require 'rails_helper'

RSpec.describe MatchResultsJob, type: :job do
  let(:tournament_service) { instance_double(BusinessLogic::TournamentService) }
  let(:tournament) { instance_double(Tournament, name: 'Test Championship', match_results: match_results_relation) }
  let(:match_results_relation) { instance_double(ActiveRecord::Associations::CollectionProxy) }
  let(:calculation_service) { instance_double(BusinessLogic::MatchResultsCalculationService) }

  before do
    allow(BusinessLogic::TournamentService).to receive(:new).and_return(tournament_service)
    allow(BusinessLogic::MatchResultsCalculationService).to receive(:new).with(tournament).and_return(calculation_service)
    allow(match_results_relation).to receive(:exists?).and_return(false)
    allow(calculation_service).to receive(:calculate)
  end

  describe '#perform' do
    context 'when a previous tournament exists with no results' do
      before do
        allow(tournament_service).to receive(:previous_tournament).and_return(tournament)
        allow(Rails.logger).to receive(:info)
      end

      it 'calls calculate on the calculation service' do
        expect(calculation_service).to receive(:calculate)
        described_class.perform_now
      end
    end

    context 'when tournament already has match results (idempotency guard)' do
      before do
        allow(tournament_service).to receive(:previous_tournament).and_return(tournament)
        allow(match_results_relation).to receive(:exists?).and_return(true)
        allow(Rails.logger).to receive(:info)
      end

      it 'does not call calculate' do
        expect(calculation_service).not_to receive(:calculate)
        described_class.perform_now
      end
    end

    context 'when no previous tournament exists' do
      before do
        allow(tournament_service).to receive(:previous_tournament).and_return(nil)
      end

      it 'returns nil without calling calculate' do
        expect(calculation_service).not_to receive(:calculate)
        expect(described_class.perform_now).to be_nil
      end
    end

    context 'when calculation service raises an error' do
      before do
        allow(tournament_service).to receive(:previous_tournament).and_return(tournament)
        allow(calculation_service).to receive(:calculate).and_raise(StandardError, 'DB connection failed')
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)
      end

      it 're-raises the error so Sidekiq marks the job as failed' do
        expect { described_class.perform_now }.to raise_error(StandardError, 'DB connection failed')
      end

      it 'logs the error before re-raising' do
        begin
          described_class.perform_now
        rescue StandardError
          nil
        end
        expect(Rails.logger).to have_received(:error).with(/MatchResultsJob failed for tournament Test Championship: DB connection failed/)
      end
    end
  end
end

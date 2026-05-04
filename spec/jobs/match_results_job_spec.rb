require 'rails_helper'

RSpec.describe MatchResultsJob, type: :job do
  let(:tournament_service) { instance_double(BusinessLogic::TournamentService) }
  let(:tournament) do
    instance_double(Tournament, id: 99, name: 'Test Championship',
                                match_results: match_results_relation)
  end
  let(:match_results_relation) { instance_double(ActiveRecord::Associations::CollectionProxy) }
  let(:calculation_service) { instance_double(BusinessLogic::MatchResultsCalculationService) }

  before do
    allow(BusinessLogic::TournamentService).to receive(:new).and_return(tournament_service)
    allow(BusinessLogic::MatchResultsCalculationService).to receive(:new).with(tournament).and_return(calculation_service)
    allow(match_results_relation).to receive(:exists?).and_return(false)
    allow(calculation_service).to receive(:calculate)
    allow(tournament).to receive(:update_column).with(:concluded, true)
  end

  describe '#perform' do
    context 'when called without tournament_id (Monday cron path)' do
      before do
        allow(tournament_service).to receive(:previous_tournament).and_return(tournament)
        allow(Rails.logger).to receive(:info)
      end

      it 'uses previous_tournament from TournamentService' do
        expect(tournament_service).to receive(:previous_tournament)
        described_class.perform_now
      end

      it 'calls calculate on the calculation service' do
        expect(calculation_service).to receive(:calculate)
        described_class.perform_now
      end

      it 'marks the tournament as concluded after calculating' do
        expect(tournament).to receive(:update_column).with(:concluded, true)
        described_class.perform_now
      end
    end

    context 'when called with a tournament_id (leaderboard trigger path)' do
      before do
        allow(Tournament).to receive(:find).with(99).and_return(tournament)
        allow(Rails.logger).to receive(:info)
      end

      it 'looks up tournament by id instead of using TournamentService' do
        expect(Tournament).to receive(:find).with(99)
        expect(tournament_service).not_to receive(:previous_tournament)
        described_class.perform_now(99)
      end

      it 'calculates and concludes the tournament' do
        expect(calculation_service).to receive(:calculate)
        expect(tournament).to receive(:update_column).with(:concluded, true)
        described_class.perform_now(99)
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

      it 'does not mark tournament as concluded' do
        expect(tournament).not_to receive(:update_column)
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
        described_class.perform_now rescue nil
        expect(Rails.logger).to have_received(:error).with(/MatchResultsJob failed for tournament Test Championship: DB connection failed/)
      end

      it 'does not mark tournament as concluded on failure' do
        described_class.perform_now rescue nil
        expect(tournament).not_to have_received(:update_column).with(:concluded, true)
      end
    end
  end
end

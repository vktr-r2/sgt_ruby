require 'rails_helper'

RSpec.describe BusinessLogic::DraftWindowService do
  let(:tournament) { create(:tournament, start_date: Time.zone.parse('2024-06-21 00:00:00')) } # Friday tournament
  let(:service) { described_class.new(tournament) }

  describe '#draft_open?' do
    context 'when current time is before draft window' do
      before { allow(Time.zone).to receive(:now).and_return(Time.zone.parse('2024-06-18 10:00:00')) } # Tuesday

      it 'returns false' do
        expect(service.draft_open?).to be false
      end
    end

    context 'when current time is at draft window start' do
      before { allow(Time.zone).to receive(:now).and_return(Time.zone.parse('2024-06-19 00:00:00')) } # Wednesday 00:00

      it 'returns true' do
        expect(service.draft_open?).to be true
      end
    end

    context 'when current time is during draft window' do
      before { allow(Time.zone).to receive(:now).and_return(Time.zone.parse('2024-06-20 15:00:00')) } # Thursday afternoon

      it 'returns true' do
        expect(service.draft_open?).to be true
      end
    end

    context 'when current time is at draft window end' do
      before { allow(Time.zone).to receive(:now).and_return(Time.zone.parse('2024-06-20 23:59:59')) } # Thursday 23:59:59

      it 'returns true' do
        expect(service.draft_open?).to be true
      end
    end

    context 'when current time is after draft window' do
      before { allow(Time.zone).to receive(:now).and_return(Time.zone.parse('2024-06-21 00:00:01')) } # Friday 00:00:01

      it 'returns false' do
        expect(service.draft_open?).to be false
      end
    end

    context 'when no tournament is provided' do
      let(:service) { described_class.new(nil) }

      it 'returns false' do
        expect(service.draft_open?).to be false
      end
    end
  end

  describe '#draft_window_status' do
    context 'when current time is before draft window' do
      before { allow(Time.zone).to receive(:now).and_return(Time.zone.parse('2024-06-18 10:00:00')) } # Tuesday

      it 'returns :before_window' do
        expect(service.draft_window_status).to eq :before_window
      end
    end

    context 'when current time is during draft window' do
      before { allow(Time.zone).to receive(:now).and_return(Time.zone.parse('2024-06-20 15:00:00')) } # Thursday afternoon

      it 'returns :open' do
        expect(service.draft_window_status).to eq :open
      end
    end

    context 'when current time is after draft window' do
      before { allow(Time.zone).to receive(:now).and_return(Time.zone.parse('2024-06-21 08:00:00')) } # Friday morning

      it 'returns :after_window' do
        expect(service.draft_window_status).to eq :after_window
      end
    end

    context 'when no tournament is provided' do
      let(:service) { described_class.new(nil) }

      it 'returns :no_tournament' do
        expect(service.draft_window_status).to eq :no_tournament
      end
    end
  end

  describe '#time_until_draft_opens' do
    context 'when draft window has not started' do
      before { allow(Time.zone).to receive(:now).and_return(Time.zone.parse('2024-06-18 12:00:00')) } # Tuesday noon

      it 'returns positive time until draft opens' do
        expected_seconds = (Time.zone.parse('2024-06-19 00:00:00') - Time.zone.parse('2024-06-18 12:00:00')).to_i
        expect(service.time_until_draft_opens).to eq expected_seconds
      end
    end

    context 'when draft window is open' do
      before { allow(Time.zone).to receive(:now).and_return(Time.zone.parse('2024-06-20 10:00:00')) } # Thursday

      it 'returns 0' do
        expect(service.time_until_draft_opens).to eq 0
      end
    end

    context 'when draft window has passed' do
      before { allow(Time.zone).to receive(:now).and_return(Time.zone.parse('2024-06-21 10:00:00')) } # Friday

      it 'returns 0' do
        expect(service.time_until_draft_opens).to eq 0
      end
    end

    context 'when no tournament is provided' do
      let(:service) { described_class.new(nil) }

      it 'returns nil' do
        expect(service.time_until_draft_opens).to be_nil
      end
    end
  end

  describe '#time_until_draft_closes' do
    context 'when draft window has not started' do
      before { allow(Time.zone).to receive(:now).and_return(Time.zone.parse('2024-06-18 12:00:00')) } # Tuesday noon

      it 'returns positive time until draft closes' do
        expected_seconds = (tournament.draft_window_end - Time.zone.parse('2024-06-18 12:00:00'))
        expect(service.time_until_draft_closes).to eq expected_seconds
      end
    end

    context 'when draft window is open' do
      before { allow(Time.zone).to receive(:now).and_return(Time.zone.parse('2024-06-20 10:00:00')) } # Thursday

      it 'returns positive time until draft closes' do
        expected_seconds = (tournament.draft_window_end - Time.zone.parse('2024-06-20 10:00:00'))
        expect(service.time_until_draft_closes).to eq expected_seconds
      end
    end

    context 'when draft window has passed' do
      before { allow(Time.zone).to receive(:now).and_return(Time.zone.parse('2024-06-21 10:00:00')) } # Friday

      it 'returns 0' do
        expect(service.time_until_draft_closes).to eq 0
      end
    end

    context 'when no tournament is provided' do
      let(:service) { described_class.new(nil) }

      it 'returns nil' do
        expect(service.time_until_draft_closes).to be_nil
      end
    end
  end

  describe 'with different tournament start days' do
    context 'when tournament starts on Wednesday' do
      let(:tournament) { create(:tournament, start_date: Time.zone.parse('2024-06-19 00:00:00')) } # Wednesday tournament

      it 'has draft window on Monday-Tuesday' do
        expect(tournament.draft_window_start).to eq Time.zone.parse('2024-06-17 00:00:00') # Monday
        expect(tournament.draft_window_end).to eq Time.zone.parse('2024-06-18 23:59:59.999999999') # Tuesday
      end

      context 'when current time is Monday during draft window' do
        before { allow(Time.zone).to receive(:now).and_return(Time.zone.parse('2024-06-17 14:00:00')) } # Monday afternoon

        it 'returns draft is open' do
          expect(service.draft_open?).to be true
          expect(service.draft_window_status).to eq :open
        end
      end
    end

    context 'when tournament starts on Sunday' do
      let(:tournament) { create(:tournament, start_date: Time.zone.parse('2024-06-23 00:00:00')) } # Sunday tournament

      it 'has draft window on Friday-Saturday' do
        expect(tournament.draft_window_start).to eq Time.zone.parse('2024-06-21 00:00:00') # Friday
        expect(tournament.draft_window_end).to eq Time.zone.parse('2024-06-22 23:59:59.999999999') # Saturday
      end

      context 'when current time is Saturday during draft window' do
        before { allow(Time.zone).to receive(:now).and_return(Time.zone.parse('2024-06-22 18:00:00')) } # Saturday evening

        it 'returns draft is open' do
          expect(service.draft_open?).to be true
          expect(service.draft_window_status).to eq :open
        end
      end
    end
  end

  describe 'integration with TournamentService' do
    let(:tournament_service) { instance_double(BusinessLogic::TournamentService) }
    let(:service) { described_class.new }

    before do
      allow(BusinessLogic::TournamentService).to receive(:new).and_return(tournament_service)
      allow(tournament_service).to receive(:current_tournament).and_return(tournament)
    end

    it 'uses current tournament when no tournament is provided' do
      expect(service.draft_open?).to eq tournament.draft_window_open?
    end
  end
end

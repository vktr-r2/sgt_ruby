require 'rails_helper'

RSpec.describe Tournament, type: :model do
  subject { build(:tournament) }

  describe 'validations' do
    it { should validate_presence_of(:tournament_id) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }
    it { should validate_presence_of(:week_number) }
    it { should validate_presence_of(:year) }
    it { should validate_presence_of(:format) }

    it 'is valid with all required attributes' do
      tournament = build(:tournament)
      expect(tournament).to be_valid
    end

    it 'is invalid without tournament_id' do
      tournament = build(:tournament, tournament_id: nil)
      expect(tournament).not_to be_valid
      expect(tournament.errors[:tournament_id]).to include("can't be blank")
    end

    it 'is invalid without name' do
      tournament = build(:tournament, name: nil)
      expect(tournament).not_to be_valid
      expect(tournament.errors[:name]).to include("can't be blank")
    end

    describe 'date validations' do
      it 'is invalid without start_date' do
        tournament = build(:tournament, start_date: nil)
        expect(tournament).not_to be_valid
        expect(tournament.errors[:start_date]).to include("can't be blank")
      end

      it 'is invalid without end_date' do
        tournament = build(:tournament, end_date: nil)
        expect(tournament).not_to be_valid
        expect(tournament.errors[:end_date]).to include("can't be blank")
      end

      it 'accepts valid date ranges' do
        tournament = build(:tournament,
                           start_date: Date.current,
                           end_date: Date.current + 3.days)
        expect(tournament).to be_valid
      end
    end

    describe 'numeric validations' do
      it 'is invalid without week_number' do
        tournament = build(:tournament, week_number: nil)
        expect(tournament).not_to be_valid
        expect(tournament.errors[:week_number]).to include("can't be blank")
      end

      it 'is invalid without year' do
        tournament = build(:tournament, year: nil)
        expect(tournament).not_to be_valid
        expect(tournament.errors[:year]).to include("can't be blank")
      end

      it 'accepts valid week numbers' do
        tournament = build(:tournament, week_number: 25)
        expect(tournament).to be_valid
      end

      it 'accepts valid years' do
        tournament = build(:tournament, year: 2024)
        expect(tournament).to be_valid
      end
    end

    it 'is invalid without format' do
      tournament = build(:tournament, format: nil)
      expect(tournament).not_to be_valid
      expect(tournament.errors[:format]).to include("can't be blank")
    end
  end

  describe 'associations' do
    it { should have_many(:match_picks).with_foreign_key('tournament_id').with_primary_key('id').dependent(:destroy) }

    it 'can have associated golfers via unique_id' do
      tournament = create(:tournament)
      golfer = create(:golfer, last_active_tourney: tournament.unique_id)

      # Test the association works by finding golfers
      associated_golfers = Golfer.where(last_active_tourney: tournament.unique_id)
      expect(associated_golfers).to include(golfer)
    end

    it 'can have associated match picks' do
      tournament = create(:tournament)
      user = create(:user)
      match_pick = create(:match_pick, tournament: tournament, user_id: user.id)

      expect(tournament.match_picks).to include(match_pick)
    end

    it 'destroys associated match_picks when tournament is deleted' do
      tournament = create(:tournament)
      user = create(:user)
      match_pick = create(:match_pick, tournament: tournament, user_id: user.id)

      expect { tournament.destroy }.to change(MatchPick, :count).by(-1)
      expect { match_pick.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'draft window methods' do
    let(:tournament) { create(:tournament, start_date: Time.zone.parse('2024-06-21 00:00:00')) } # Friday tournament

    describe '#draft_window_start' do
      it 'returns two days before tournament start date at beginning of day' do
        expected_time = Time.zone.parse('2024-06-19 00:00:00') # Wednesday 00:00:00
        expect(tournament.draft_window_start).to eq expected_time
      end
    end

    describe '#draft_window_end' do
      it 'returns one day before tournament start date at end of day' do
        expected_time = Time.zone.parse('2024-06-20 23:59:59.999999999') # Thursday 23:59:59.999999999
        expect(tournament.draft_window_end).to eq expected_time
      end
    end

    describe '#draft_window_open?' do
      context 'when current time is before draft window' do
        it 'returns false' do
          current_time = Time.zone.parse('2024-06-18 10:00:00') # Tuesday
          expect(tournament.draft_window_open?(current_time)).to be false
        end
      end

      context 'when current time is at draft window start' do
        it 'returns true' do
          current_time = Time.zone.parse('2024-06-19 00:00:00') # Wednesday 00:00:00
          expect(tournament.draft_window_open?(current_time)).to be true
        end
      end

      context 'when current time is during draft window' do
        it 'returns true' do
          current_time = Time.zone.parse('2024-06-20 15:00:00') # Thursday afternoon
          expect(tournament.draft_window_open?(current_time)).to be true
        end
      end

      context 'when current time is at draft window end' do
        it 'returns true' do
          current_time = Time.zone.parse('2024-06-20 23:59:59') # Thursday 23:59:59
          expect(tournament.draft_window_open?(current_time)).to be true
        end
      end

      context 'when current time is after draft window' do
        it 'returns false' do
          current_time = Time.zone.parse('2024-06-21 00:00:01') # Friday 00:00:01
          expect(tournament.draft_window_open?(current_time)).to be false
        end
      end

      context 'when no time is provided' do
        it 'uses current time zone time' do
          allow(Time.zone).to receive(:now).and_return(Time.zone.parse('2024-06-20 12:00:00'))
          expect(tournament.draft_window_open?).to be true
        end
      end
    end

    describe 'different tournament start days' do
      context 'when tournament starts on Wednesday' do
        let(:tournament) { create(:tournament, start_date: Time.zone.parse('2024-06-19 00:00:00')) }

        it 'has draft window on Monday-Tuesday' do
          expect(tournament.draft_window_start).to eq Time.zone.parse('2024-06-17 00:00:00') # Monday
          expect(tournament.draft_window_end).to eq Time.zone.parse('2024-06-18 23:59:59.999999999') # Tuesday
        end

        it 'is open during Monday' do
          current_time = Time.zone.parse('2024-06-17 14:00:00') # Monday afternoon
          expect(tournament.draft_window_open?(current_time)).to be true
        end

        it 'is open during Tuesday' do
          current_time = Time.zone.parse('2024-06-18 20:00:00') # Tuesday evening
          expect(tournament.draft_window_open?(current_time)).to be true
        end

        it 'is closed on Wednesday tournament day' do
          current_time = Time.zone.parse('2024-06-19 08:00:00') # Wednesday morning
          expect(tournament.draft_window_open?(current_time)).to be false
        end
      end

      context 'when tournament starts on Sunday' do
        let(:tournament) { create(:tournament, start_date: Time.zone.parse('2024-06-23 00:00:00')) }

        it 'has draft window on Friday-Saturday' do
          expect(tournament.draft_window_start).to eq Time.zone.parse('2024-06-21 00:00:00') # Friday
          expect(tournament.draft_window_end).to eq Time.zone.parse('2024-06-22 23:59:59.999999999') # Saturday
        end

        it 'is open during weekend draft window' do
          current_time = Time.zone.parse('2024-06-22 18:00:00') # Saturday evening
          expect(tournament.draft_window_open?(current_time)).to be true
        end
      end
    end
  end

  describe 'factory' do
    it 'creates a valid tournament with factory' do
      tournament = create(:tournament)
      expect(tournament).to be_persisted
      expect(tournament).to be_valid
      expect(tournament.unique_id).to be_present
    end
  end
end

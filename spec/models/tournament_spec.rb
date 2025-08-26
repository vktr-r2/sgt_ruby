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

  describe 'factory' do
    it 'creates a valid tournament with factory' do
      tournament = create(:tournament)
      expect(tournament).to be_persisted
      expect(tournament).to be_valid
      expect(tournament.unique_id).to be_present
    end
  end
end
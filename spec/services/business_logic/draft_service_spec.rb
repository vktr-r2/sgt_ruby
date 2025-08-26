require 'rails_helper'

RSpec.describe BusinessLogic::DraftService do
  let(:tournament) { create(:tournament) }
  let(:golfers) { create_list(:golfer, 12, last_active_tourney: tournament.unique_id) }
  let(:user) { create(:user) }
  
  subject(:service) { described_class.new(user) }

  before do
    allow_any_instance_of(BusinessLogic::TournamentService)
      .to receive(:current_tournament).and_return(tournament)
    allow_any_instance_of(BusinessLogic::GolferService)
      .to receive(:get_current_tourn_golfers).and_return(golfers)
  end

  describe '#initialize' do
    it 'sets up the service with current user' do
      expect(service.instance_variable_get(:@current_user)).to eq(user)
      expect(service.instance_variable_get(:@current_tournament)).to eq(tournament)
      expect(service.instance_variable_get(:@current_tourn_golfers)).to eq(golfers)
    end

    it 'can accept user ID as integer' do
      service = described_class.new(user.id)
      expect(service.instance_variable_get(:@current_user)).to eq(user.id)
    end

    it 'defaults to user ID 1 if no user provided' do
      service = described_class.new
      expect(service.instance_variable_get(:@current_user)).to eq(1)
    end
  end

  describe '#get_current_user_picks_for_tourn' do
    context 'when user has no picks' do
      it 'returns empty collection' do
        picks = service.get_current_user_picks_for_tourn
        expect(picks).to be_empty
      end
    end

    context 'when user has picks' do
      let!(:match_picks) do
        create_list(:match_pick, 3, 
                   user_id: user.id, 
                   tournament: tournament,
                   golfer_id: golfers.first.id)
      end

      it 'returns the user picks for current tournament' do
        picks = service.get_current_user_picks_for_tourn
        expect(picks.count).to eq(3)
        expect(picks).to all(be_a(MatchPick))
        expect(picks.map(&:user_id)).to all(eq(user.id))
        expect(picks.map(&:tournament_id)).to all(eq(tournament.id))
      end
    end

    context 'when user has picks for different tournaments' do
      let(:other_tournament) { create(:tournament) }
      
      let!(:current_picks) do
        create_list(:match_pick, 2, 
                   user_id: user.id, 
                   tournament: tournament,
                   golfer_id: golfers.first.id)
      end
      
      let!(:other_picks) do
        create_list(:match_pick, 3, 
                   user_id: user.id, 
                   tournament: other_tournament,
                   golfer_id: golfers.first.id)
      end

      it 'returns only picks for current tournament' do
        picks = service.get_current_user_picks_for_tourn
        expect(picks.count).to eq(2)
        expect(picks.map(&:tournament_id)).to all(eq(tournament.id))
      end
    end
  end

  describe '#get_draft_review_data' do
    let!(:match_picks) do
      create_list(:match_pick, 4, 
                 user_id: user.id, 
                 tournament: tournament,
                 golfer_id: golfers.first.id)
    end

    it 'returns hash with tournament and pick data' do
      data = service.get_draft_review_data
      
      expect(data).to be_a(Hash)
      expect(data).to have_key(:tournament_name)
      expect(data).to have_key(:year)
      expect(data).to have_key(:picks)
      
      expect(data[:tournament_name]).to eq(tournament.name)
      expect(data[:year]).to eq(Date.today.year)
      expect(data[:picks]).to eq(match_picks)
    end

    it 'returns current year regardless of tournament year' do
      data = service.get_draft_review_data
      expect(data[:year]).to eq(Date.today.year)
    end
  end

  describe '#validate_picks' do
    let(:user_service) { instance_double(BusinessLogic::UserService) }
    let(:user_ids) { [user.id, create(:user).id, create(:user).id] }

    before do
      allow(BusinessLogic::UserService).to receive(:new).and_return(user_service)
      allow(user_service).to receive(:get_user_ids).and_return(user_ids)
    end

    it 'validates picks for all users' do
      expect(service).to receive(:validate_user_picks).exactly(3).times
      service.validate_picks
    end

    context 'when user has no picks' do
      it 'calls randomizer for user without picks' do
        allow(service).to receive(:get_user_picks_for_tourn).and_return([])
        expect(service).to receive(:adams_awesome_randomizer).with(user.id, [])
        
        service.send(:validate_user_picks, user.id)
      end
    end

    context 'when user has existing picks' do
      let!(:existing_picks) do
        create_list(:match_pick, 3, 
                   user_id: user.id, 
                   tournament: tournament,
                   golfer_id: golfers.first.id)
      end

      it 'does not call randomizer for user with picks' do
        expect(service).not_to receive(:adams_awesome_randomizer)
        service.send(:validate_user_picks, user.id)
      end
    end
  end

  describe "Adam's Awesome Randomizer" do
    describe '#adams_awesome_randomizer' do
      let(:empty_picks) { [] }

      it 'creates exactly 8 picks for the user' do
        expect do
          service.send(:adams_awesome_randomizer, user.id, empty_picks)
        end.to change(MatchPick, :count).by(8)
      end

      it 'creates picks with priorities 1 through 8' do
        service.send(:adams_awesome_randomizer, user.id, empty_picks)
        
        priorities = MatchPick.where(user_id: user.id, tournament: tournament).pluck(:priority).sort
        expect(priorities).to eq([1, 2, 3, 4, 5, 6, 7, 8])
      end

      it 'creates picks with unique golfers' do
        service.send(:adams_awesome_randomizer, user.id, empty_picks)
        
        golfer_ids = MatchPick.where(user_id: user.id, tournament: tournament).pluck(:golfer_id)
        expect(golfer_ids.uniq).to eq(golfer_ids)
      end

      it 'selects golfers from available tournament golfers' do
        service.send(:adams_awesome_randomizer, user.id, empty_picks)
        
        golfer_ids = MatchPick.where(user_id: user.id, tournament: tournament).pluck(:golfer_id)
        available_golfer_ids = golfers.map(&:id)
        
        expect(golfer_ids).to all(be_in(available_golfer_ids))
      end
    end

    describe '#random_pick' do
      let(:current_picks) { [] }

      it 'returns a golfer from available golfers' do
        random_golfer = service.send(:random_pick, current_picks)
        expect(golfers).to include(random_golfer)
      end

      it 'avoids duplicate picks' do
        # Simulate already picked golfers
        already_picked = [golfers.first, golfers.second]
        
        100.times do # Test randomness
          random_golfer = service.send(:random_pick, already_picked)
          expect(already_picked).not_to include(random_golfer)
        end
      end

      it 'can handle when most golfers are already picked' do
        # Leave only 2 golfers available
        already_picked = golfers[0..-3]
        
        10.times do
          random_golfer = service.send(:random_pick, already_picked)
          expect(already_picked).not_to include(random_golfer)
          expect(golfers[-2..-1]).to include(random_golfer)
        end
      end
    end

    describe '#is_pick_dupe?' do
      let(:picked_golfer) { golfers.first }
      let(:new_golfer) { golfers.second }

      it 'returns true when golfer is already picked' do
        current_picks = [picked_golfer]
        expect(service.send(:is_pick_dupe?, current_picks, picked_golfer)).to be true
      end

      it 'returns false when golfer is not picked' do
        current_picks = [picked_golfer]
        expect(service.send(:is_pick_dupe?, current_picks, new_golfer)).to be false
      end

      it 'returns false for empty picks' do
        current_picks = []
        expect(service.send(:is_pick_dupe?, current_picks, picked_golfer)).to be false
      end
    end
  end

  describe '#create_match_pick' do
    it 'creates a match pick with correct attributes' do
      expect do
        service.send(:create_match_pick, user.id, golfers.first.id, 1)
      end.to change(MatchPick, :count).by(1)
      
      pick = MatchPick.last
      expect(pick.user_id).to eq(user.id)
      expect(pick.golfer_id).to eq(golfers.first.id)
      expect(pick.priority).to eq(1)
      expect(pick.tournament_id).to eq(tournament.id)
    end
  end

  describe '#get_user_picks_for_tourn' do
    let(:other_user) { create(:user) }
    
    let!(:user_picks) do
      create_list(:match_pick, 3, 
                 user_id: user.id, 
                 tournament: tournament,
                 golfer_id: golfers.first.id)
    end
    
    let!(:other_user_picks) do
      create_list(:match_pick, 2, 
                 user_id: other_user.id, 
                 tournament: tournament,
                 golfer_id: golfers.second.id)
    end

    it 'returns picks only for specified user' do
      picks = service.send(:get_user_picks_for_tourn, user.id)
      expect(picks.count).to eq(3)
      expect(picks.map(&:user_id)).to all(eq(user.id))
    end

    it 'returns picks only for current tournament' do
      other_tournament = create(:tournament)
      create(:match_pick, 
             user_id: user.id, 
             tournament: other_tournament,
             golfer_id: golfers.first.id)

      picks = service.send(:get_user_picks_for_tourn, user.id)
      expect(picks.count).to eq(3)
      expect(picks.map(&:tournament_id)).to all(eq(tournament.id))
    end

    it 'returns empty array when user has no picks' do
      picks = service.send(:get_user_picks_for_tourn, 999) # Non-existent user
      expect(picks).to eq([])
    end
  end

  describe 'integration scenarios' do
    it 'handles full draft validation workflow' do
      user_with_picks = create(:user)
      user_without_picks = create(:user)
      
      # Create picks for one user
      create_list(:match_pick, 8, 
                 user_id: user_with_picks.id, 
                 tournament: tournament,
                 golfer_id: golfers.first.id)
      
      user_service = instance_double(BusinessLogic::UserService)
      allow(BusinessLogic::UserService).to receive(:new).and_return(user_service)
      allow(user_service).to receive(:get_user_ids).and_return([user_with_picks.id, user_without_picks.id])
      
      expect do
        service.validate_picks
      end.to change(MatchPick, :count).by(8)
      
      # User with picks should still have 8 picks
      expect(MatchPick.where(user_id: user_with_picks.id).count).to eq(8)
      
      # User without picks should now have 8 randomized picks
      expect(MatchPick.where(user_id: user_without_picks.id).count).to eq(8)
    end
  end
end
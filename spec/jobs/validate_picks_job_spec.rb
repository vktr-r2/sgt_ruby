require 'rails_helper'

RSpec.describe ValidatePicksJob, type: :job do
  let(:tournament) { create(:tournament) }
  
  let!(:golfers) do
    # Create golfers with the tournament's unique_id
    10.times.map do |i|
      create(:golfer, 
             f_name: "Player#{i}", 
             l_name: "Test#{i}",
             last_active_tourney: tournament.unique_id)
    end
  end

  before do
    allow_any_instance_of(BusinessLogic::TournamentService)
      .to receive(:current_tournament).and_return(tournament)
    allow_any_instance_of(BusinessLogic::GolferService)
      .to receive(:get_current_tourn_golfers).and_return(golfers)
  end

  describe "#perform" do
    it "validates picks for all users" do
      user_with_picks = create(:user, :with_token)
      user_without_picks = create(:user, :with_token)
      
      # Create picks for first user
      create_list(:match_pick, 8, user: user_with_picks, tournament: tournament)
      
      # Ensure second user has no picks
      expect(MatchPick.where(user: user_without_picks).count).to eq(0)
      
      # Perform the job
      ValidatePicksJob.new.perform
      
      # First user should still have their picks
      expect(MatchPick.where(user: user_with_picks).count).to eq(8)
      
      # Second user should now have randomized picks
      expect(MatchPick.where(user: user_without_picks).count).to eq(8)
      
      # Verify randomized picks have proper priorities
      priorities = MatchPick.where(user: user_without_picks).pluck(:priority).sort
      expect(priorities).to eq([1, 2, 3, 4, 5, 6, 7, 8])
      
      # Verify all picks are for valid golfers
      golfer_ids = MatchPick.where(user: user_without_picks).pluck(:golfer_id)
      expect(golfer_ids).to all(be_in(golfers.map(&:id)))
      
      # Verify no duplicate golfers
      expect(golfer_ids.uniq).to eq(golfer_ids)
    end
    
    it "does not affect users who already have picks" do
      user_with_picks = create(:user, :with_token)
      
      # Create specific picks for the user
      original_picks = []
      (1..8).each do |priority|
        pick = create(:match_pick, 
                     user: user_with_picks, 
                     tournament: tournament, 
                     golfer: golfers[priority - 1],
                     priority: priority)
        original_picks << pick
      end
      
      # Perform the job
      ValidatePicksJob.new.perform
      
      # Verify picks are unchanged
      current_picks = MatchPick.where(user: user_with_picks).order(:priority)
      expect(current_picks.count).to eq(8)
      
      original_picks.each_with_index do |original_pick, index|
        current_pick = current_picks[index]
        expect(current_pick.golfer_id).to eq(original_pick.golfer_id)
        expect(current_pick.priority).to eq(original_pick.priority)
      end
    end
    
    it "handles users with partial picks by leaving them unchanged" do
      user_with_partial_picks = create(:user, :with_token)
      
      # Create only 3 picks (partial)
      create_list(:match_pick, 3, user: user_with_partial_picks, tournament: tournament)
      
      # Perform the job
      ValidatePicksJob.new.perform
      
      # User should still have only 3 picks (not randomized to 8)
      # This tests that the job only randomizes users with NO picks
      expect(MatchPick.where(user: user_with_partial_picks).count).to eq(3)
    end
  end
end
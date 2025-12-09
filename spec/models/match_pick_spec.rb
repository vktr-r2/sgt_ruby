require 'rails_helper'

RSpec.describe MatchPick, type: :model do
  let(:tournament) { create(:tournament) }
  let(:user) { create(:user) }
  let(:golfer) { create(:golfer, last_active_tourney: tournament.unique_id) }

  subject { build(:match_pick, tournament: tournament, user_id: user.id, golfer_id: golfer.id) }

  describe 'associations' do
    it { should belong_to(:tournament) }

    it 'belongs to a valid tournament' do
      match_pick = create(:match_pick, tournament: tournament, user_id: user.id, golfer_id: golfer.id)
      expect(match_pick.tournament).to eq(tournament)
    end

    it 'is invalid without a tournament' do
      match_pick = build(:match_pick, tournament: nil, user_id: user.id, golfer_id: golfer.id)
      expect(match_pick).not_to be_valid
      expect(match_pick.errors[:tournament]).to include("must exist")
    end
  end

  describe 'attributes' do
    it 'has user_id, golfer_id, and priority attributes' do
      match_pick = create(:match_pick,
                          tournament: tournament,
                          user_id: user.id,
                          golfer_id: golfer.id,
                          priority: 3)

      expect(match_pick.user_id).to eq(user.id)
      expect(match_pick.golfer_id).to eq(golfer.id)
      expect(match_pick.priority).to eq(3)
      expect(match_pick.tournament_id).to eq(tournament.id)
    end

    it 'can store tournament association correctly' do
      match_pick = create(:match_pick, tournament: tournament, user_id: user.id, golfer_id: golfer.id)
      expect(match_pick.tournament_id).to eq(tournament.id)
      expect(match_pick.tournament).to eq(tournament)
    end
  end

  describe 'draft pick scenarios' do
    it 'can create multiple picks for same user in same tournament' do
      pick1 = create(:match_pick, tournament: tournament, user_id: user.id, golfer_id: golfer.id, priority: 1)

      golfer2 = create(:golfer, last_active_tourney: tournament.unique_id)
      pick2 = create(:match_pick, tournament: tournament, user_id: user.id, golfer_id: golfer2.id, priority: 2)

      expect(MatchPick.where(user_id: user.id, tournament: tournament).count).to eq(2)
      expect(pick1.priority).to eq(1)
      expect(pick2.priority).to eq(2)
    end

    it 'can create picks for different users in same tournament' do
      user2 = create(:user)

      pick1 = create(:match_pick, tournament: tournament, user_id: user.id, golfer_id: golfer.id)
      pick2 = create(:match_pick, tournament: tournament, user_id: user2.id, golfer_id: golfer.id)

      expect(MatchPick.where(tournament: tournament).count).to eq(2)
      expect(pick1.user_id).not_to eq(pick2.user_id)
    end

    it 'can create full draft set (8 picks) for a user' do
      golfers = create_list(:golfer, 8, last_active_tourney: tournament.unique_id)

      picks = golfers.map.with_index(1) do |golfer, priority|
        create(:match_pick,
               tournament: tournament,
               user_id: user.id,
               golfer_id: golfer.id,
               priority: priority)
      end

      expect(picks.length).to eq(8)
      expect(MatchPick.where(user_id: user.id, tournament: tournament).count).to eq(8)

      priorities = MatchPick.where(user_id: user.id, tournament: tournament).pluck(:priority).sort
      expect(priorities).to eq([ 1, 2, 3, 4, 5, 6, 7, 8 ])
    end
  end

  describe 'factory' do
    it 'creates a valid match_pick with factory' do
      match_pick = create(:match_pick, tournament: tournament, user_id: user.id, golfer_id: golfer.id)
      expect(match_pick).to be_persisted
      expect(match_pick).to be_valid
    end
  end
end

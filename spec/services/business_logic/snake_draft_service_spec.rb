require 'rails_helper'

RSpec.describe BusinessLogic::SnakeDraftService, type: :service do
  let(:service) { described_class.new }

  let!(:users) do
    [
      create(:user, name: "User1"),
      create(:user, name: "User2"),
      create(:user, name: "User3"),
      create(:user, name: "User4")
    ]
  end

  let!(:current_tournament) do
    create(:tournament,
           name: "Current Tournament",
           start_date: Date.today + 2.days,
           year: Date.today.year,
           week_number: Date.today.strftime("%V").to_i)
  end

  let!(:golfers) do
    32.times.map { |i| create(:golfer, f_name: "Golfer#{i}", l_name: "Test") }
  end

  before do
    # Create 8 picks for each user for current tournament (all drafted: false)
    users.each_with_index do |user, user_index|
      8.times do |priority|
        golfer = golfers[user_index * 8 + priority]
        create(:match_pick,
               user: user,
               tournament: current_tournament,
               golfer: golfer,
               priority: priority + 1,
               drafted: false)
      end
    end

    allow_any_instance_of(BusinessLogic::TournamentService)
      .to receive(:current_tournament).and_return(current_tournament)
  end

  describe "#execute_draft" do
    context "when there is no previous tournament data" do
      it "randomizes draft order and assigns picks" do
        result = service.execute_draft(current_tournament)

        expect(result[:success]).to be true
        expect(result[:draft_order].length).to eq(4)
        expect(result[:assigned_picks]).to eq(32) # 4 users * 8 picks

        # Verify all picks are now drafted
        drafted_picks = MatchPick.where(tournament: current_tournament, drafted: true)
        expect(drafted_picks.count).to eq(32)
      end
    end
  end
end

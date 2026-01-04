require "rails_helper"

RSpec.describe "Api::TournamentsController", type: :request do
  let(:user) { create(:user, :with_token) }
  let(:headers) { { "Authorization" => "Bearer #{user.authentication_token}" } }

  describe "GET /api/tournaments/current/scores" do
    context "with authentication" do
      context "with current tournament and scores" do
        let(:tournament) { create(:tournament) }
        let!(:users) { create_list(:user, 4) }
        let!(:golfers) { create_list(:golfer, 16, tournament: tournament) }

        before do
          # Mock current_tournament to return our tournament
          allow_any_instance_of(BusinessLogic::TournamentService)
            .to receive(:current_tournament).and_return(tournament)

          # Create drafted picks with scores for each user
          users.each_with_index do |u, user_index|
            golfers.sample(4).each_with_index do |golfer, pick_index|
              match_pick = create(:match_pick,
                user: u,
                tournament: tournament,
                golfer: golfer,
                drafted: true,
                priority: pick_index + 1)

              # Create scores for 2 rounds
              2.times do |round_num|
                create(:score,
                  match_pick: match_pick,
                  round: round_num + 1,
                  score: 70 + user_index + pick_index,
                  position: "T#{(user_index * 4 + pick_index + 1)}",
                  status: "active")
              end
            end
          end
        end

        it "returns successful response" do
          get "/api/tournaments/current/scores", headers: headers
          expect(response).to have_http_status(:ok)
        end

        it "returns tournament data" do
          get "/api/tournaments/current/scores", headers: headers
          json_response = JSON.parse(response.body)

          expect(json_response["success"]).to be true
          expect(json_response["data"]).to have_key("tournament")
          expect(json_response["data"]).to have_key("leaderboard")

          tournament_data = json_response["data"]["tournament"]
          expect(tournament_data["id"]).to eq(tournament.id)
          expect(tournament_data["name"]).to eq(tournament.name)
        end

        it "includes all users with their drafted golfers" do
          get "/api/tournaments/current/scores", headers: headers
          json_response = JSON.parse(response.body)

          leaderboard = json_response["data"]["leaderboard"]
          expect(leaderboard.length).to eq(4)

          leaderboard.each do |entry|
            expect(entry).to have_key("user_id")
            expect(entry).to have_key("username")
            expect(entry).to have_key("total_strokes")
            expect(entry).to have_key("current_position")
            expect(entry).to have_key("golfers")
            expect(entry["golfers"].length).to eq(4)
          end
        end

        it "calculates total strokes correctly" do
          get "/api/tournaments/current/scores", headers: headers
          json_response = JSON.parse(response.body)

          leaderboard = json_response["data"]["leaderboard"]
          first_entry = leaderboard.first

          # Each golfer has 2 rounds, calculate expected total
          expected_total = first_entry["golfers"].sum do |golfer|
            golfer["rounds"].sum { |r| r["score"] }
          end

          expect(first_entry["total_strokes"]).to eq(expected_total)
        end

        it "includes round-by-round scores" do
          get "/api/tournaments/current/scores", headers: headers
          json_response = JSON.parse(response.body)

          leaderboard = json_response["data"]["leaderboard"]
          first_golfer = leaderboard.first["golfers"].first

          expect(first_golfer).to have_key("rounds")
          expect(first_golfer["rounds"].length).to eq(2)

          first_golfer["rounds"].each do |round|
            expect(round).to have_key("round")
            expect(round).to have_key("score")
            expect(round).to have_key("position")
          end
        end

        it "marks replaced golfers correctly" do
          # Create a pick with original_golfer_id
          replaced_golfer = golfers.last
          original_golfer = golfers.first
          match_pick = create(:match_pick,
            user: users.first,
            tournament: tournament,
            golfer: replaced_golfer,
            original_golfer_id: original_golfer.id,
            drafted: true,
            priority: 5)

          create(:score,
            match_pick: match_pick,
            round: 1,
            score: 72,
            position: "T10",
            status: "active")

          get "/api/tournaments/current/scores", headers: headers
          json_response = JSON.parse(response.body)

          # Find the user with the replaced golfer
          user_entry = json_response["data"]["leaderboard"].find { |e| e["user_id"] == users.first.id }
          replaced_golfer_data = user_entry["golfers"].find { |g| g["golfer_id"] == replaced_golfer.id }

          expect(replaced_golfer_data["was_replaced"]).to be true
        end
      end

      context "with no current tournament" do
        before do
          allow_any_instance_of(BusinessLogic::TournamentService)
            .to receive(:current_tournament).and_return(nil)
        end

        it "returns null tournament and empty leaderboard" do
          get "/api/tournaments/current/scores", headers: headers
          json_response = JSON.parse(response.body)

          expect(json_response["success"]).to be true
          expect(json_response["data"]["tournament"]).to be_nil
          expect(json_response["data"]["leaderboard"]).to eq([])
        end
      end
    end

    context "without authentication" do
      it "returns 401 unauthorized" do
        get "/api/tournaments/current/scores"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

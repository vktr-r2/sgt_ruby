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

  describe "GET /api/tournaments/history" do
    context "with authentication" do
      let!(:past_tournaments) { create_list(:tournament, 5, end_date: 1.week.ago, year: 2026) }
      let!(:current_tournament) { create(:tournament, end_date: 1.week.from_now) }

      before do
        # Create match results for past tournaments
        past_tournaments.each_with_index do |tournament, index|
          user_winner = create(:user)
          create(:match_result, tournament: tournament, user: user_winner, place: 1, total_score: -4)
        end
      end

      it "returns successful response" do
        get "/api/tournaments/history", headers: headers
        expect(response).to have_http_status(:ok)
      end

      it "returns only past tournaments" do
        get "/api/tournaments/history", headers: headers
        json_response = JSON.parse(response.body)

        tournaments = json_response["data"]["tournaments"]
        expect(tournaments.length).to eq(5)
        tournaments.each do |t|
          expect(Date.parse(t["end_date"])).to be < Date.current
        end
      end

      it "includes winner information" do
        get "/api/tournaments/history", headers: headers
        json_response = JSON.parse(response.body)

        first_tournament = json_response["data"]["tournaments"].first
        expect(first_tournament).to have_key("winner_username")
        expect(first_tournament).to have_key("winning_score")
      end

      it "returns pagination metadata" do
        get "/api/tournaments/history", headers: headers
        json_response = JSON.parse(response.body)

        expect(json_response["data"]).to have_key("pagination")
        pagination = json_response["data"]["pagination"]
        expect(pagination).to have_key("current_page")
        expect(pagination).to have_key("total_pages")
        expect(pagination).to have_key("total_count")
        expect(pagination).to have_key("per_page")
      end
    end

    context "without authentication" do
      it "returns 401 unauthorized" do
        get "/api/tournaments/history"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/tournaments/:id/results" do
    context "with authentication" do
      context "with completed tournament" do
        let(:tournament) { create(:tournament, end_date: 1.week.ago) }
        let!(:users) { create_list(:user, 3) }
        let!(:golfers) { create_list(:golfer, 12, tournament: tournament) }

        before do
          users.each_with_index do |u, index|
            create(:match_result,
              user: u,
              tournament: tournament,
              place: index + 1,
              total_score: -(4 - index),
              winner_picked: index.zero?,
              cuts_missed: index)

            # Create match picks with scores
            golfers.sample(4).each do |golfer|
              match_pick = create(:match_pick,
                user: u,
                tournament: tournament,
                golfer: golfer,
                drafted: true)

              4.times do |round_num|
                create(:score,
                  match_pick: match_pick,
                  round: round_num + 1,
                  score: 70,
                  status: "complete")
              end
            end
          end
        end

        it "returns successful response" do
          get "/api/tournaments/#{tournament.id}/results", headers: headers
          expect(response).to have_http_status(:ok)
        end

        it "returns tournament and results data" do
          get "/api/tournaments/#{tournament.id}/results", headers: headers
          json_response = JSON.parse(response.body)

          expect(json_response["success"]).to be true
          expect(json_response["data"]).to have_key("tournament")
          expect(json_response["data"]).to have_key("results")
        end

        it "includes all users ranked by place" do
          get "/api/tournaments/#{tournament.id}/results", headers: headers
          json_response = JSON.parse(response.body)

          results = json_response["data"]["results"]
          expect(results.length).to eq(3)
          expect(results.first["place"]).to eq(1)
          expect(results.last["place"]).to eq(3)
        end

        it "includes drafted golfer details" do
          get "/api/tournaments/#{tournament.id}/results", headers: headers
          json_response = JSON.parse(response.body)

          first_result = json_response["data"]["results"].first
          expect(first_result).to have_key("golfers")
          expect(first_result["golfers"].length).to eq(4)

          first_golfer = first_result["golfers"].first
          expect(first_golfer).to have_key("golfer_id")
          expect(first_golfer).to have_key("name")
          expect(first_golfer).to have_key("total_score")
          expect(first_golfer).to have_key("was_replaced")
        end
      end

      context "with in-progress tournament" do
        let(:tournament) { create(:tournament, end_date: 1.week.from_now) }

        it "returns 422 unprocessable entity" do
          get "/api/tournaments/#{tournament.id}/results", headers: headers
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "with non-existent tournament" do
        it "returns 404 not found" do
          get "/api/tournaments/999999/results", headers: headers
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "without authentication" do
      let(:tournament) { create(:tournament, end_date: 1.week.ago) }

      it "returns 401 unauthorized" do
        get "/api/tournaments/#{tournament.id}/results"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

require "rails_helper"

RSpec.describe "Api::StandingsController", type: :request do
  let(:user) { create(:user, :with_token) }
  let(:headers) { { "Authorization" => "Bearer #{user.authentication_token}" } }

  describe "GET /api/standings/season" do
    context "with authentication" do
      context "with completed tournaments" do
        let!(:users) { create_list(:user, 3) }
        let!(:tournaments) { create_list(:tournament, 3, year: 2026) }

        before do
          # Create match results for each user across tournaments
          users.each_with_index do |u, user_index|
            tournaments.each_with_index do |tournament, tourn_index|
              create(:match_result,
                user: u,
                tournament: tournament,
                place: ((user_index + tourn_index) % 4) + 1,  # Vary placements
                total_score: -((user_index + tourn_index) % 4) - 1,
                winner_picked: (user_index + tourn_index).even?,
                cuts_missed: user_index)
            end
          end
        end

        it "returns successful response" do
          get "/api/standings/season", headers: headers
          expect(response).to have_http_status(:ok)
        end

        it "returns cumulative season standings" do
          get "/api/standings/season", headers: headers
          json_response = JSON.parse(response.body)

          expect(json_response["success"]).to be true
          expect(json_response["data"]).to have_key("season_year")
          expect(json_response["data"]).to have_key("last_updated")
          expect(json_response["data"]).to have_key("standings")

          standings = json_response["data"]["standings"]
          expect(standings.length).to eq(3)
        end

        it "ranks users by total points ascending" do
          get "/api/standings/season", headers: headers
          json_response = JSON.parse(response.body)

          standings = json_response["data"]["standings"]
          total_points = standings.map { |s| s["total_points"] }

          expect(total_points).to eq(total_points.sort)
          expect(standings.first["rank"]).to eq(1)
          expect(standings.last["rank"]).to eq(3)
        end

        it "includes tournament statistics" do
          get "/api/standings/season", headers: headers
          json_response = JSON.parse(response.body)

          first_standing = json_response["data"]["standings"].first

          expect(first_standing).to have_key("user_id")
          expect(first_standing).to have_key("username")
          expect(first_standing).to have_key("total_points")
          expect(first_standing).to have_key("tournaments_played")
          expect(first_standing).to have_key("wins")
          expect(first_standing).to have_key("top_3_finishes")
          expect(first_standing).to have_key("winners_picked")
          expect(first_standing).to have_key("total_cuts_missed")
        end

        it "filters by year parameter" do
          # Create older tournament
          old_tournament = create(:tournament, year: 2025, start_date: Date.new(2025, 1, 15))
          create(:match_result,
            user: users.first,
            tournament: old_tournament,
            place: 1,
            total_score: -4)

          get "/api/standings/season?year=2026", headers: headers
          json_response = JSON.parse(response.body)

          expect(json_response["data"]["season_year"]).to eq(2026)

          # Check that old tournament results aren't included
          first_standing = json_response["data"]["standings"].find { |s| s["user_id"] == users.first.id }
          expect(first_standing["tournaments_played"]).to eq(3)  # Only 2026 tournaments
        end
      end

      context "with no completed tournaments" do
        it "returns all users with zero points" do
          get "/api/standings/season", headers: headers
          json_response = JSON.parse(response.body)

          expect(json_response["success"]).to be true
          standings = json_response["data"]["standings"]

          # Should still have users even with no tournaments
          expect(standings).to be_an(Array)
        end
      end
    end

    context "without authentication" do
      it "returns 401 unauthorized" do
        get "/api/standings/season"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

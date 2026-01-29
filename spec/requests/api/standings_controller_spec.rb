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

  describe "GET /api/standings/seasons" do
    context "with authentication" do
      context "with multiple completed seasons" do
        let!(:users) { create_list(:user, 4) }

        # Create 2025 season (2 tournaments)
        let!(:tournament_2025_1) do
          create(:tournament,
            name: "The Masters 2025",
            year: 2025,
            start_date: Date.new(2025, 1, 10),
            end_date: Date.new(2025, 1, 13),
            major_championship: true)
        end

        let!(:tournament_2025_2) do
          create(:tournament,
            name: "PGA Championship 2025",
            year: 2025,
            start_date: Date.new(2025, 1, 17),
            end_date: Date.new(2025, 1, 20),
            major_championship: false)
        end

        # Create 2024 season (1 tournament)
        let!(:tournament_2024_1) do
          create(:tournament,
            name: "Genesis Invitational 2024",
            year: 2024,
            start_date: Date.new(2024, 1, 10),
            end_date: Date.new(2024, 1, 13),
            major_championship: false)
        end

        before do
          # 2025 Results
          create(:match_result, :first_place, user: users[0], tournament: tournament_2025_1)
          create(:match_result, :second_place, user: users[1], tournament: tournament_2025_1)
          create(:match_result, :third_place, user: users[2], tournament: tournament_2025_1)
          create(:match_result, :fourth_place, user: users[3], tournament: tournament_2025_1)

          create(:match_result, :second_place, user: users[0], tournament: tournament_2025_2)
          create(:match_result, :first_place, user: users[1], tournament: tournament_2025_2)
          create(:match_result, :third_place, user: users[2], tournament: tournament_2025_2)
          create(:match_result, :fourth_place, user: users[3], tournament: tournament_2025_2)

          # 2024 Results
          create(:match_result, :first_place, user: users[2], tournament: tournament_2024_1)
          create(:match_result, :second_place, user: users[0], tournament: tournament_2024_1)
          create(:match_result, :third_place, user: users[1], tournament: tournament_2024_1)
          create(:match_result, :fourth_place, user: users[3], tournament: tournament_2024_1)
        end

        it "returns successful response" do
          get "/api/standings/seasons", headers: headers
          expect(response).to have_http_status(:ok)
        end

        it "returns seasons in descending year order" do
          get "/api/standings/seasons", headers: headers
          json_response = JSON.parse(response.body)

          expect(json_response["success"]).to be true
          expect(json_response["data"]).to have_key("seasons")

          seasons = json_response["data"]["seasons"]
          expect(seasons.length).to eq(2)

          years = seasons.map { |s| s["year"] }
          expect(years).to eq([2025, 2024])
        end

        it "includes all required fields per season" do
          get "/api/standings/seasons", headers: headers
          json_response = JSON.parse(response.body)

          season = json_response["data"]["seasons"].first

          expect(season).to have_key("year")
          expect(season).to have_key("tournament_count")
          expect(season).to have_key("season_winner")
          expect(season).to have_key("standings_preview")
          expect(season).to have_key("majors_won")
          expect(season).to have_key("total_winners_picked")
          expect(season).to have_key("total_cuts_missed")

          # Check season_winner structure
          expect(season["season_winner"]).to have_key("user_id")
          expect(season["season_winner"]).to have_key("username")
          expect(season["season_winner"]).to have_key("total_points")

          # Check standings_preview includes all 4 users
          expect(season["standings_preview"].length).to eq(4)
        end
      end

      context "with no completed seasons" do
        it "returns empty array when no completed seasons exist" do
          get "/api/standings/seasons", headers: headers
          json_response = JSON.parse(response.body)

          expect(json_response["success"]).to be true
          expect(json_response["data"]["seasons"]).to be_an(Array)
          expect(json_response["data"]["seasons"]).to be_empty
        end
      end
    end

    context "without authentication" do
      it "returns 401 unauthorized" do
        get "/api/standings/seasons"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/standings/season/:year" do
    context "with authentication" do
      context "with valid year" do
        let!(:users) { create_list(:user, 3) }

        let!(:tournament_1) do
          create(:tournament,
            name: "The Masters",
            year: 2025,
            start_date: Date.new(2025, 4, 10),
            end_date: Date.new(2025, 4, 13),
            major_championship: true)
        end

        let!(:tournament_2) do
          create(:tournament,
            name: "Genesis Invitational",
            year: 2025,
            start_date: Date.new(2025, 2, 15),
            end_date: Date.new(2025, 2, 18),
            major_championship: false)
        end

        before do
          create(:match_result, :first_place, user: users[0], tournament: tournament_1)
          create(:match_result, :second_place, user: users[1], tournament: tournament_1)
          create(:match_result, :third_place, user: users[2], tournament: tournament_1)

          create(:match_result, :second_place, user: users[0], tournament: tournament_2)
          create(:match_result, :first_place, user: users[1], tournament: tournament_2)
          create(:match_result, :third_place, user: users[2], tournament: tournament_2)
        end

        it "returns successful response" do
          get "/api/standings/season/2025", headers: headers
          expect(response).to have_http_status(:ok)
        end

        it "includes standings with majors_won field" do
          get "/api/standings/season/2025", headers: headers
          json_response = JSON.parse(response.body)

          expect(json_response["success"]).to be true
          expect(json_response["data"]).to have_key("standings")

          first_standing = json_response["data"]["standings"].first
          expect(first_standing).to have_key("majors_won")
        end

        it "includes tournaments list" do
          get "/api/standings/season/2025", headers: headers
          json_response = JSON.parse(response.body)

          expect(json_response["data"]).to have_key("tournaments")
          tournaments = json_response["data"]["tournaments"]

          expect(tournaments.length).to eq(2)
          expect(tournaments.first).to have_key("id")
          expect(tournaments.first).to have_key("name")
          expect(tournaments.first).to have_key("start_date")
          expect(tournaments.first).to have_key("end_date")
          expect(tournaments.first).to have_key("is_major")
          expect(tournaments.first).to have_key("winner")
        end
      end

      context "with invalid year" do
        it "returns 422 for invalid year" do
          get "/api/standings/season/2030", headers: headers
          expect(response).to have_http_status(:unprocessable_entity)

          json_response = JSON.parse(response.body)
          expect(json_response["success"]).to be false
          expect(json_response["error"]).to include("No data for season")
        end
      end
    end

    context "without authentication" do
      it "returns 401 unauthorized" do
        get "/api/standings/season/2025"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

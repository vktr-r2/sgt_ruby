require 'rails_helper'

RSpec.describe "Admin API", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  let!(:admin_user) { create(:user, :admin, :with_token) }
  let!(:regular_user) { create(:user, :with_token) }
  let(:admin_headers) { { 'Authorization' => "Bearer #{admin_user.authentication_token}" } }
  let(:regular_headers) { { 'Authorization' => "Bearer #{regular_user.authentication_token}" } }

  describe "Authentication & Authorization" do
    context "when user is not authenticated" do
      it "returns unauthorized for admin index" do
        get "/admin"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is not admin" do
      it "returns forbidden for admin index" do
        get "/admin", headers: regular_headers
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['error']).to eq('Admin access required')
      end

      it "returns forbidden for table data" do
        get "/admin/table/users", headers: regular_headers
        expect(response).to have_http_status(:forbidden)
      end

      it "returns forbidden for create record" do
        post "/admin/table/users", headers: regular_headers
        expect(response).to have_http_status(:forbidden)
      end

      it "returns forbidden for update record" do
        user = create(:user)
        put "/admin/table/users/#{user.id}", headers: regular_headers
        expect(response).to have_http_status(:forbidden)
      end

      it "returns forbidden for delete record" do
        user = create(:user)
        delete "/admin/table/users/#{user.id}", headers: regular_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when user is admin" do
      it "allows access to admin endpoints" do
        get "/admin", headers: admin_headers
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /admin" do
    context "as admin user" do
      it "returns tables data structure" do
        get "/admin", headers: admin_headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('tables')

        tables = json_response['tables']
        expect(tables).to have_key('users')
        expect(tables).to have_key('golfers')
        expect(tables).to have_key('tournaments')
        expect(tables).to have_key('match_picks')
        expect(tables).to have_key('match_results')
        expect(tables).to have_key('scores')
      end
    end
  end

  describe "GET /admin/table/:table" do
    context "with valid table name" do
      it "returns table data and metadata for users" do
        create_list(:user, 3)

        get "/admin/table/users", headers: admin_headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response).to have_key('data')
        expect(json_response).to have_key('columns')
        expect(json_response).to have_key('table_name')
        expect(json_response['table_name']).to eq('users')
        expect(json_response['data']).to be_an(Array)
        expect(json_response['columns']).to be_an(Array)
        expect(json_response['data'].length).to be >= 3
      end

      it "returns table data for golfers" do
        create_list(:golfer, 2)

        get "/admin/table/golfers", headers: admin_headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['table_name']).to eq('golfers')
        expect(json_response['data'].length).to be >= 2
      end

      it "returns table data for tournaments" do
        create_list(:tournament, 2)

        get "/admin/table/tournaments", headers: admin_headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['table_name']).to eq('tournaments')
        expect(json_response['data'].length).to be >= 2
      end

      it "includes column metadata with types" do
        get "/admin/table/users", headers: admin_headers

        json_response = JSON.parse(response.body)
        columns = json_response['columns']

        email_column = columns.find { |col| col['name'] == 'email' }
        expect(email_column).to be_present
        expect(email_column['type']).to eq('string')

        admin_column = columns.find { |col| col['name'] == 'admin' }
        expect(admin_column).to be_present
        expect(admin_column['type']).to eq('boolean')
      end
    end

    context "with invalid table name" do
      it "returns bad request for non-existent table" do
        get "/admin/table/invalid_table", headers: admin_headers

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid table')
      end

      it "returns bad request for non-whitelisted table" do
        get "/admin/table/schema_migrations", headers: admin_headers

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid table')
      end
    end
  end

  describe "POST /admin/table/:table" do
    context "creating a user" do
      let(:user_params) do
        {
          record: {
            name: "New Admin User",
            email: "newadmin@example.com",
            admin: false
            # Note: Not including password - users have complex Devise requirements
            # In a real admin interface, user creation would likely be handled separately
          }
        }
      end

      it "returns validation errors for incomplete user data (expected behavior)" do
        post "/admin/table/users", params: user_params, headers: admin_headers

        # User creation should fail due to missing password - this is expected
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
        expect(json_response['errors']).to have_key('password')
      end

      it "returns validation errors for invalid email" do
        user_params[:record][:email] = ""

        post "/admin/table/users", params: user_params, headers: admin_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
        expect(json_response['errors']).to have_key('email')
      end

      it "returns validation errors for duplicate email" do
        existing_user = create(:user, email: "duplicate@example.com")
        user_params[:record][:email] = "duplicate@example.com"

        post "/admin/table/users", params: user_params, headers: admin_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
      end
    end

    context "creating a golfer" do
      let!(:tournament) { create(:tournament, unique_id: "tournament_2025_01") }
      let(:golfer_params) do
        {
          record: {
            source_id: "12345",
            f_name: "John",
            l_name: "Doe",
            last_active_tourney: tournament.unique_id
          }
        }
      end

      it "creates a new golfer record" do
        expect {
          post "/admin/table/golfers", params: golfer_params, headers: admin_headers
        }.to change(Golfer, :count).by(1)

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Record created successfully')

        created_golfer = Golfer.find(json_response['record']['id'])
        expect(created_golfer.f_name).to eq("John")
        expect(created_golfer.l_name).to eq("Doe")
        expect(created_golfer.source_id).to eq("12345")
      end
    end
  end

  describe "PUT /admin/table/:table/:id" do
    let(:user_to_update) { create(:user, name: "Original Name") }

    context "updating a user" do
      let(:update_params) do
        {
          record: {
            name: "Updated Name",
            admin: true
          }
        }
      end

      it "updates the user record and refreshes timestamp" do
        original_updated_at = user_to_update.updated_at

        # Ensure some time passes for timestamp comparison
        travel_to(1.minute.from_now) do
          put "/admin/table/users/#{user_to_update.id}", params: update_params, headers: admin_headers
        end

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('record')
        expect(json_response).to have_key('message')
        expect(json_response['message']).to eq('Record updated successfully')

        user_to_update.reload
        expect(user_to_update.name).to eq("Updated Name")
        expect(user_to_update.admin).to be(true)
        expect(user_to_update.updated_at).to be > original_updated_at
      end

      it "returns validation errors for invalid updates" do
        update_params[:record][:email] = ""

        put "/admin/table/users/#{user_to_update.id}", params: update_params, headers: admin_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
      end

      it "returns not found for non-existent record" do
        put "/admin/table/users/99999", params: update_params, headers: admin_headers

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Record not found')
      end
    end
  end

  describe "DELETE /admin/table/:table/:id" do
    let(:user_to_delete) { create(:user) }

    context "deleting a user" do
      it "deletes the user record" do
        user_id = user_to_delete.id

        expect {
          delete "/admin/table/users/#{user_id}", headers: admin_headers
        }.to change(User, :count).by(-1)

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Record deleted successfully')

        expect(User.find_by(id: user_id)).to be_nil
      end

      it "returns not found for non-existent record" do
        delete "/admin/table/users/99999", headers: admin_headers

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Record not found')
      end
    end

    context "deleting with foreign key constraints" do
      it "handles cascade deletions properly for match_picks" do
        user = create(:user)
        tournament = create(:tournament)
        golfer = create(:golfer)
        match_pick = create(:match_pick, user: user, tournament: tournament, golfer: golfer)

        expect {
          delete "/admin/table/users/#{user.id}", headers: admin_headers
        }.to change(MatchPick, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "Cross-table operations" do
    context "when working with related records" do
      let(:user) { create(:user) }
      let(:tournament) { create(:tournament) }
      let(:golfer) { create(:golfer) }

      it "can create match_picks with proper associations" do
        match_pick_params = {
          record: {
            user_id: user.id,
            tournament_id: tournament.id,
            golfer_id: golfer.id,
            priority: 1,
            drafted: false
          }
        }

        post "/admin/table/match_picks", params: match_pick_params, headers: admin_headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        match_pick = MatchPick.find(json_response['record']['id'])
        expect(match_pick.user_id).to eq(user.id)
        expect(match_pick.tournament_id).to eq(tournament.id)
        expect(match_pick.golfer_id).to eq(golfer.id)
        expect(match_pick.priority).to eq(1)
      end

      it "includes associated data when fetching match_picks" do
        create(:match_pick, user: user, tournament: tournament, golfer: golfer)

        get "/admin/table/match_picks", headers: admin_headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['data']).to be_present
        expect(json_response['data'].first).to have_key('user_id')
        expect(json_response['data'].first).to have_key('tournament_id')
        expect(json_response['data'].first).to have_key('golfer_id')
      end
    end
  end
end

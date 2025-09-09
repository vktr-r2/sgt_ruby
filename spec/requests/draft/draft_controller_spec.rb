require 'rails_helper'

RSpec.describe 'Draft::DraftController', type: :request do
  let(:user) { create(:user, :with_token) }
  let(:tournament) { create(:tournament) }
  let(:golfers) { create_list(:golfer, 10, last_active_tourney: tournament.unique_id) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{user.authentication_token}" } }

  before do
    allow_any_instance_of(BusinessLogic::TournamentService)
      .to receive(:current_tournament).and_return(tournament)
    allow_any_instance_of(BusinessLogic::GolferService)
      .to receive(:get_current_tourn_golfers).and_return(golfers)
    allow_any_instance_of(BusinessLogic::DraftService)
      .to receive(:get_draft_review_data).and_return({
        tournament_name: tournament.name,
        year: Date.current.year,
        picks: []
      })
  end

  describe 'GET /draft' do
    context 'without authentication' do
      it 'returns unauthorized' do
        get '/draft'
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Unauthorized')
      end
    end

    context 'with valid authentication' do
      context 'when golfers are not available (unavailable mode)' do
        before do
          allow_any_instance_of(BusinessLogic::GolferService)
            .to receive(:get_current_tourn_golfers).and_return([])
        end

        it 'returns unavailable mode' do
          get '/draft', headers: auth_headers

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['mode']).to eq('unavailable')
          expect(json_response['golfers']).to be_empty
          expect(json_response['tournament']).to include('name' => tournament.name)
          expect(json_response['picks']).to be_empty
        end
      end

      context 'during draft window with no existing picks (pick mode)' do
        before do
          # Set tournament to start on Friday, so draft window is Wednesday-Thursday
          tournament.update!(start_date: Time.zone.parse('2024-06-21 00:00:00')) # Friday
          # Mock current time to be during draft window (Thursday)
          current_time = Time.zone.parse('2024-06-20 10:00:00') # Thursday
          allow(Time.zone).to receive(:now).and_return(current_time)
          
          allow_any_instance_of(BusinessLogic::DraftService)
            .to receive(:get_draft_review_data).and_return({
              tournament_name: tournament.name,
              year: Date.current.year,
              picks: [] # No existing picks
            })
        end

        it 'returns pick mode with available golfers' do
          get '/draft', headers: auth_headers

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['mode']).to eq('pick')
          expect(json_response['golfers']).to have(10).items
          expect(json_response['tournament']).to include('name' => tournament.name)
          expect(json_response['picks']).to be_empty
          
          # Verify golfer structure
          golfer = json_response['golfers'].first
          expect(golfer).to include('id', 'first_name', 'last_name', 'full_name')
        end

        it 'returns properly formatted golfer data' do
          get '/draft', headers: auth_headers

          json_response = JSON.parse(response.body)
          golfer = json_response['golfers'].first
          original_golfer = golfers.first
          
          expect(golfer['id']).to eq(original_golfer.id)
          expect(golfer['first_name']).to eq(original_golfer.f_name)
          expect(golfer['last_name']).to eq(original_golfer.l_name)
          expect(golfer['full_name']).to eq("#{original_golfer.f_name} #{original_golfer.l_name}")
        end
      end

      context 'during draft time (Wednesday) with no existing picks' do
        before do
          # Mock current time to be Wednesday
          wednesday = Time.zone.parse('2024-06-19 15:00:00') # Wednesday
          allow(Time.zone).to receive(:now).and_return(wednesday)
          
          allow_any_instance_of(BusinessLogic::DraftService)
            .to receive(:get_draft_review_data).and_return({
              tournament_name: tournament.name,
              year: Date.current.year,
              picks: []
            })
        end

        it 'returns pick mode on Wednesday as well' do
          get '/draft', headers: auth_headers

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['mode']).to eq('pick')
        end
      end

      context 'outside draft time or with existing picks (review mode)' do
        let!(:existing_picks) do
          create_list(:match_pick, 3, 
                     user_id: user.id, 
                     tournament: tournament,
                     golfer_id: golfers.first.id)
        end

        before do
          # Mock current time to be Thursday (outside draft window)
          thursday = Time.zone.parse('2024-06-20 10:00:00') # Thursday
          allow(Time.zone).to receive(:now).and_return(thursday)
          
          allow_any_instance_of(BusinessLogic::DraftService)
            .to receive(:get_draft_review_data).and_return({
              tournament_name: tournament.name,
              year: Date.current.year,
              picks: existing_picks
            })
        end

        it 'returns review mode with existing picks' do
          get '/draft', headers: auth_headers

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['mode']).to eq('review')
          expect(json_response['golfers']).to have(10).items
          expect(json_response['tournament']).to include('name' => tournament.name)
          expect(json_response['picks']).to have(3).items
          
          # Verify pick structure
          pick = json_response['picks'].first
          expect(pick).to include('id', 'golfer_id', 'priority')
        end
      end

      context 'during draft time but with existing picks' do
        let!(:existing_picks) do
          create_list(:match_pick, 8, 
                     user_id: user.id, 
                     tournament: tournament,
                     golfer_id: golfers.first.id)
        end

        before do
          # Mock current time to be Tuesday (draft time)
          tuesday = Time.zone.parse('2024-06-18 10:00:00') # Tuesday
          allow(Time.zone).to receive(:now).and_return(tuesday)
          
          allow_any_instance_of(BusinessLogic::DraftService)
            .to receive(:get_draft_review_data).and_return({
              tournament_name: tournament.name,
              year: Date.current.year,
              picks: existing_picks
            })
        end

        it 'returns review mode even during draft time if picks exist' do
          get '/draft', headers: auth_headers

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          
          expect(json_response['mode']).to eq('review')
          expect(json_response['picks']).to have(8).items
        end
      end
    end
  end

  describe 'POST /draft' do
    let(:valid_picks) do
      golfers[0..7].map { |golfer| { golfer_id: golfer.id } }
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        post '/draft', params: { picks: valid_picks }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with valid authentication' do
      context 'with valid picks data' do
        it 'creates match picks successfully' do
          expect do
            post '/draft', params: { picks: valid_picks }, headers: auth_headers, as: :json
          end.to change(MatchPick, :count).by(8)

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response['message']).to eq('Picks submitted successfully!')
        end

        it 'creates picks with correct priorities and golfers' do
          post '/draft', params: { picks: valid_picks }, headers: auth_headers, as: :json

          created_picks = MatchPick.where(user_id: user.id, tournament: tournament).order(:priority)
          expect(created_picks.count).to eq(8)

          valid_picks.each_with_index do |pick_data, index|
            created_pick = created_picks[index]
            expect(created_pick.golfer_id).to eq(pick_data[:golfer_id])
            expect(created_pick.priority).to eq(index + 1)
            expect(created_pick.user_id).to eq(user.id)
            expect(created_pick.tournament_id).to eq(tournament.id)
          end
        end

        it 'clears existing picks before creating new ones' do
          # Create some existing picks
          existing_picks = create_list(:match_pick, 3, 
                                     user_id: user.id, 
                                     tournament: tournament,
                                     golfer_id: golfers.last.id)

          expect do
            post '/draft', params: { picks: valid_picks }, headers: auth_headers, as: :json
          end.to change(MatchPick, :count).by(5) # Removes 3, adds 8 = net +5

          # Should only have the new picks
          remaining_picks = MatchPick.where(user_id: user.id, tournament: tournament)
          expect(remaining_picks.count).to eq(8)
          
          # Old picks should be gone
          existing_picks.each do |old_pick|
            expect { old_pick.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end

        it 'handles string keys in pick data' do
          string_key_picks = golfers[0..7].map { |golfer| { "golfer_id" => golfer.id } }
          
          post '/draft', params: { picks: string_key_picks }, headers: auth_headers, as: :json
          
          expect(response).to have_http_status(:ok)
          expect(MatchPick.where(user_id: user.id, tournament: tournament).count).to eq(8)
        end
      end

      context 'with invalid picks data' do
        it 'handles empty picks array' do
          post '/draft', params: { picks: [] }, headers: auth_headers, as: :json

          expect(response).to have_http_status(:ok)
          expect(MatchPick.where(user_id: user.id, tournament: tournament).count).to eq(0)
        end

        it 'handles picks with missing golfer_id' do
          invalid_picks = [{ golfer_id: golfers.first.id }, { priority: 2 }]
          
          post '/draft', params: { picks: invalid_picks }, headers: auth_headers, as: :json
          
          expect(response).to have_http_status(:ok)
          # Only creates picks with valid golfer_id
          expect(MatchPick.where(user_id: user.id, tournament: tournament).count).to eq(1)
        end

        it 'handles picks with invalid golfer_id' do
          invalid_picks = [{ golfer_id: 99999 }] # Non-existent golfer
          
          expect do
            post '/draft', params: { picks: invalid_picks }, headers: auth_headers, as: :json
          end.to raise_error(ActiveRecord::InvalidForeignKey).or raise_error(ActiveRecord::RecordInvalid)
        end

        it 'handles missing picks parameter' do
          post '/draft', params: {}, headers: auth_headers, as: :json
          
          expect(response).to have_http_status(:ok)
          expect(MatchPick.where(user_id: user.id, tournament: tournament).count).to eq(0)
        end
      end

      context 'error handling' do
        it 'returns error response when database operation fails' do
          allow_any_instance_of(MatchPick).to receive(:save!).and_raise(StandardError.new("Database error"))
          
          post '/draft', params: { picks: valid_picks }, headers: auth_headers, as: :json
          
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to include('Error submitting picks')
        end
      end
    end

    context 'with different users' do
      let(:other_user) { create(:user, :with_token) }
      let(:other_auth_headers) { { 'Authorization' => "Bearer #{other_user.authentication_token}" } }

      it 'creates picks for the correct user' do
        post '/draft', params: { picks: valid_picks }, headers: auth_headers, as: :json
        post '/draft', params: { picks: valid_picks[0..2] }, headers: other_auth_headers, as: :json

        user_picks = MatchPick.where(user_id: user.id, tournament: tournament)
        other_user_picks = MatchPick.where(user_id: other_user.id, tournament: tournament)

        expect(user_picks.count).to eq(8)
        expect(other_user_picks.count).to eq(3)
        expect(user_picks.map(&:user_id)).to all(eq(user.id))
        expect(other_user_picks.map(&:user_id)).to all(eq(other_user.id))
      end

      it 'does not affect other users picks when creating new ones' do
        # Other user creates picks first
        post '/draft', params: { picks: valid_picks[0..4] }, headers: other_auth_headers, as: :json
        other_user_picks_count = MatchPick.where(user_id: other_user.id).count
        
        # Current user creates picks
        post '/draft', params: { picks: valid_picks }, headers: auth_headers, as: :json

        # Other user's picks should be unchanged
        expect(MatchPick.where(user_id: other_user.id).count).to eq(other_user_picks_count)
        expect(MatchPick.where(user_id: user.id).count).to eq(8)
      end
    end
  end

  describe 'JSON response structure' do
    before do
      tuesday = Time.zone.parse('2024-06-18 10:00:00') # Tuesday
      allow(Time.zone).to receive(:now).and_return(tuesday)
    end

    it 'returns consistent JSON structure for all modes' do
      get '/draft', headers: auth_headers

      json_response = JSON.parse(response.body)
      
      expect(json_response).to include('mode', 'golfers', 'tournament', 'picks')
      expect(json_response['mode']).to be_in(['unavailable', 'pick', 'review'])
      expect(json_response['golfers']).to be_an(Array)
      expect(json_response['tournament']).to be_a(Hash)
      expect(json_response['picks']).to be_an(Array)
    end

    it 'includes required tournament fields' do
      get '/draft', headers: auth_headers

      json_response = JSON.parse(response.body)
      tournament_data = json_response['tournament']
      
      expect(tournament_data).to include('name', 'year')
      expect(tournament_data['name']).to eq(tournament.name)
      expect(tournament_data['year']).to be_an(Integer)
    end

    it 'includes required golfer fields for each golfer' do
      get '/draft', headers: auth_headers

      json_response = JSON.parse(response.body)
      json_response['golfers'].each do |golfer|
        expect(golfer).to include('id', 'first_name', 'last_name', 'full_name')
        expect(golfer['id']).to be_an(Integer)
        expect(golfer['first_name']).to be_a(String)
        expect(golfer['last_name']).to be_a(String)
        expect(golfer['full_name']).to be_a(String)
      end
    end
  end
end
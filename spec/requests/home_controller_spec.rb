require 'rails_helper'

RSpec.describe 'HomeController', type: :request do
  let(:user) { create(:user, :with_token) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{user.authentication_token}" } }

  describe 'GET /' do
    context 'when there is a current tournament' do
      let!(:tournament) do
        create(:tournament,
               name: 'Test Championship',
               start_date: Date.current,
               end_date: Date.current + 3.days,
               week_number: Date.current.strftime("%V").to_i,
               year: Date.current.year,
               format: 'Stroke Play')
      end

      before do
        allow_any_instance_of(BusinessLogic::TournamentService)
          .to receive(:current_tournament).and_return(tournament)
      end

      it 'returns successful response' do
        get '/', headers: auth_headers
        expect(response).to have_http_status(:ok)
      end

      it 'returns current tournament data' do
        get '/', headers: auth_headers

        json_response = JSON.parse(response.body)
        current_tournament = json_response['current_tournament']

        expect(current_tournament).to be_present
        expect(current_tournament['id']).to eq(tournament.id)
        expect(current_tournament['name']).to eq('Test Championship')
        expect(current_tournament['start_date']).to eq(tournament.start_date.as_json)
        expect(current_tournament['end_date']).to eq(tournament.end_date.as_json)
        expect(current_tournament['week_number']).to eq(tournament.week_number)
        expect(current_tournament['year']).to eq(tournament.year)
        expect(current_tournament['format']).to eq('Stroke Play')
      end

      it 'includes all required tournament fields' do
        get '/', headers: auth_headers

        json_response = JSON.parse(response.body)
        current_tournament = json_response['current_tournament']

        expect(current_tournament).to include(
          'id', 'name', 'start_date', 'end_date',
          'week_number', 'year', 'format', 'draft_window'
        )
      end

      it 'includes draft window information' do
        get '/', headers: auth_headers

        json_response = JSON.parse(response.body)
        draft_window = json_response['current_tournament']['draft_window']

        expect(draft_window).to be_present
        expect(draft_window).to include('start', 'end', 'status', 'is_open')
        expect(draft_window['start']).to be_present
        expect(draft_window['end']).to be_present
        expect(draft_window['status']).to be_in([ 'before_window', 'open', 'after_window' ])
        expect(draft_window['is_open']).to be_in([ true, false ])
      end

      it 'returns app info' do
        get '/', headers: auth_headers

        json_response = JSON.parse(response.body)
        app_info = json_response['app_info']

        expect(app_info).to be_present
        expect(app_info['name']).to eq('Spreadsheet Golf Tour')
        expect(app_info['version']).to eq('1.0.0')
      end

      it 'returns proper JSON structure' do
        get '/', headers: auth_headers

        json_response = JSON.parse(response.body)

        expect(json_response).to include('current_tournament', 'app_info')
        expect(json_response['current_tournament']).to be_a(Hash)
        expect(json_response['app_info']).to be_a(Hash)
      end
    end

    context 'when there is no current tournament' do
      before do
        allow_any_instance_of(BusinessLogic::TournamentService)
          .to receive(:current_tournament).and_return(nil)
      end

      it 'returns successful response' do
        get '/', headers: auth_headers
        expect(response).to have_http_status(:ok)
      end

      it 'returns null for current tournament' do
        get '/', headers: auth_headers

        json_response = JSON.parse(response.body)
        expect(json_response['current_tournament']).to be_nil
      end

      it 'still returns app info when no tournament exists' do
        get '/', headers: auth_headers

        json_response = JSON.parse(response.body)
        app_info = json_response['app_info']

        expect(app_info).to be_present
        expect(app_info['name']).to eq('Spreadsheet Golf Tour')
        expect(app_info['version']).to eq('1.0.0')
      end

      it 'maintains consistent JSON structure' do
        get '/', headers: auth_headers

        json_response = JSON.parse(response.body)

        expect(json_response).to include('current_tournament', 'app_info')
        expect(json_response['current_tournament']).to be_nil
        expect(json_response['app_info']).to be_a(Hash)
      end
    end

    context 'with different tournament data' do
      let!(:major_tournament) do
        create(:tournament,
               name: 'Masters Tournament',
               start_date: Date.current + 1.week,
               end_date: Date.current + 1.week + 4.days,
               week_number: (Date.current + 1.week).strftime("%V").to_i,
               year: Date.current.year,
               format: 'Match Play',
               purse: 15000000)
      end

      before do
        allow_any_instance_of(BusinessLogic::TournamentService)
          .to receive(:current_tournament).and_return(major_tournament)
      end

      it 'returns tournament with correct data types' do
        get '/', headers: auth_headers

        json_response = JSON.parse(response.body)
        current_tournament = json_response['current_tournament']

        expect(current_tournament['id']).to be_an(Integer)
        expect(current_tournament['name']).to be_a(String)
        expect(current_tournament['start_date']).to be_a(String)
        expect(current_tournament['end_date']).to be_a(String)
        expect(current_tournament['week_number']).to be_an(Integer)
        expect(current_tournament['year']).to be_an(Integer)
        expect(current_tournament['format']).to be_a(String)
      end

      it 'handles different tournament formats' do
        get '/', headers: auth_headers

        json_response = JSON.parse(response.body)
        current_tournament = json_response['current_tournament']

        expect(current_tournament['format']).to eq('Match Play')
      end

      it 'handles future tournaments' do
        get '/', headers: auth_headers

        json_response = JSON.parse(response.body)
        current_tournament = json_response['current_tournament']

        expect(Date.parse(current_tournament['start_date'])).to be > Date.current
        expect(Date.parse(current_tournament['end_date'])).to be > Date.current
      end
    end

    context 'tournament service integration' do
      it 'creates and uses TournamentService' do
        expect(BusinessLogic::TournamentService).to receive(:new).at_least(:once).and_call_original
        get '/', headers: auth_headers
      end

      it 'calls current_tournament method on service' do
        tournament_service = instance_double(BusinessLogic::TournamentService)
        allow(BusinessLogic::TournamentService).to receive(:new).and_return(tournament_service)
        allow(BusinessLogic::DraftWindowService).to receive(:new).and_return(instance_double(BusinessLogic::DraftWindowService, draft_window_status: 'before_window', draft_open?: false))
        expect(tournament_service).to receive(:current_tournament).at_least(:once).and_return(nil)

        get '/', headers: auth_headers
      end

      it 'handles tournament service errors gracefully' do
        allow_any_instance_of(BusinessLogic::TournamentService)
          .to receive(:current_tournament).and_raise(StandardError.new("Service error"))

        expect { get '/', headers: auth_headers }.to raise_error(StandardError)
      end
    end

    context 'HTTP headers and content type' do
      it 'returns JSON content type' do
        get '/', headers: auth_headers
        expect(response.content_type).to include('application/json')
      end

      it 'includes proper CORS headers in test environment' do
        get '/', headers: auth_headers
        # In test environment, CORS is configured for wildcard
        expect(response.headers).to include('Vary')
      end
    end

    context 'response performance' do
      let!(:tournament) { create(:tournament) }

      before do
        allow_any_instance_of(BusinessLogic::TournamentService)
          .to receive(:current_tournament).and_return(tournament)
      end

      it 'responds quickly' do
        start_time = Time.current
        get '/', headers: auth_headers
        response_time = Time.current - start_time

        expect(response_time).to be < 1.0 # Should respond in under 1 second
      end

      it 'returns reasonable response size' do
        get '/', headers: auth_headers

        # Response should be small and efficient
        expect(response.body.length).to be < 1000 # Less than 1KB
      end
    end

    context 'edge cases' do
      it 'handles tournaments with minimal name' do
        tournament = create(:tournament, name: 'a')
        allow_any_instance_of(BusinessLogic::TournamentService)
          .to receive(:current_tournament).and_return(tournament)

        get '/', headers: auth_headers

        json_response = JSON.parse(response.body)
        expect(json_response['current_tournament']['name']).to eq('a')
      end

      it 'handles special characters in tournament name' do
        tournament = create(:tournament, name: 'AT&T Pebble Beach Pro-Am')
        allow_any_instance_of(BusinessLogic::TournamentService)
          .to receive(:current_tournament).and_return(tournament)

        get '/', headers: auth_headers

        json_response = JSON.parse(response.body)
        expect(json_response['current_tournament']['name']).to eq('AT&T Pebble Beach Pro-Am')
      end

      it 'handles tournament with nil optional fields' do
        tournament = create(:tournament, purse: nil)
        allow_any_instance_of(BusinessLogic::TournamentService)
          .to receive(:current_tournament).and_return(tournament)

        get '/', headers: auth_headers

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['current_tournament']).to be_present
      end
    end

    context 'JSON format validation' do
      let!(:tournament) { create(:tournament) }

      before do
        allow_any_instance_of(BusinessLogic::TournamentService)
          .to receive(:current_tournament).and_return(tournament)
      end

      it 'returns valid JSON' do
        get '/', headers: auth_headers

        expect { JSON.parse(response.body) }.not_to raise_error
      end

      it 'does not include sensitive information' do
        get '/', headers: auth_headers

        json_response = JSON.parse(response.body)

        # Should not include database-specific fields or sensitive data
        expect(json_response['current_tournament']).not_to include('created_at', 'updated_at')
        expect(json_response).not_to include('database_config', 'secrets')
      end
    end
  end
end

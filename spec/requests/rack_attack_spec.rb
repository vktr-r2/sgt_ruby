require 'rails_helper'

RSpec.describe 'Rack::Attack', type: :request do
  before do
    # Enable Rack::Attack for these tests (disabled by default in test env)
    Rack::Attack.enabled = true
    # Clear the cache between tests
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.reset!
  end

  after do
    # Disable after tests
    Rack::Attack.enabled = false
  end

  describe 'login throttling' do
    let(:user) { create(:user, password: 'password123') }
    let(:login_params) do
      {
        user: {
          email: user.email,
          password: 'wrong_password'
        }
      }
    end

    it 'allows 5 login attempts per IP' do
      5.times do
        post '/users/sign_in', params: login_params, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it 'throttles after 5 login attempts per IP' do
      6.times do |i|
        post '/users/sign_in', params: login_params, as: :json
        if i < 5
          expect(response).to have_http_status(:unauthorized)
        else
          expect(response).to have_http_status(:too_many_requests)
        end
      end
    end

    it 'returns retry_after in response' do
      6.times { post '/users/sign_in', params: login_params, as: :json }

      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Rate limit exceeded. Try again later.')
      expect(json_response['retry_after']).to be_present
      expect(response.headers['Retry-After']).to be_present
    end
  end

  describe 'password reset throttling' do
    let(:user) { create(:user) }
    let(:reset_params) do
      {
        user: {
          email: user.email
        }
      }
    end

    it 'allows 3 password reset requests per hour per IP' do
      3.times do
        post '/users/password', params: reset_params, as: :json
        expect(response).not_to have_http_status(:too_many_requests)
      end
    end

    it 'throttles after 3 password reset requests per IP' do
      4.times do |i|
        post '/users/password', params: reset_params, as: :json
        if i < 3
          expect(response).not_to have_http_status(:too_many_requests)
        else
          expect(response).to have_http_status(:too_many_requests)
        end
      end
    end
  end

  describe 'API throttling' do
    let(:user) { create(:user, :with_token) }
    let(:headers) { { 'Authorization' => "Bearer #{user.plain_token}" } }

    it 'allows 100 API requests per minute' do
      100.times do
        get '/api/app_info', headers: headers
        expect(response).not_to have_http_status(:too_many_requests)
      end
    end

    it 'throttles after 100 API requests per minute' do
      101.times do |i|
        get '/api/app_info', headers: headers
        if i < 100
          expect(response).not_to have_http_status(:too_many_requests)
        else
          expect(response).to have_http_status(:too_many_requests)
        end
      end
    end
  end
end

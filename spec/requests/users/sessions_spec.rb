require 'rails_helper'

RSpec.describe 'Users::Sessions', type: :request do
  let(:user) { create(:user, password: 'password123') }

  describe 'POST /users/sign_in' do
    let(:login_params) do
      {
        user: {
          email: user.email,
          password: 'password123'
        }
      }
    end

    context 'with valid credentials' do
      it 'returns user data and authentication token' do
        post '/users/sign_in', params: login_params, as: :json

        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('user')
        expect(json_response).to have_key('token')
        
        user_data = json_response['user']
        expect(user_data['id']).to eq(user.id)
        expect(user_data['email']).to eq(user.email)
        expect(user_data['name']).to eq(user.name)
        expect(user_data['admin']).to eq(user.admin)
        
        expect(json_response['token']).to be_present
        expect(json_response['token'].length).to eq(20)
        
        # Verify token is saved to user
        user.reload
        expect(user.authentication_token).to eq(json_response['token'])
      end
    end

    context 'with invalid credentials' do
      let(:invalid_params) do
        {
          user: {
            email: user.email,
            password: 'wrong_password'
          }
        }
      end

      it 'returns error message' do
        post '/users/sign_in', params: invalid_params, as: :json

        expect(response).to have_http_status(:unauthorized)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid credentials')
      end
    end

    context 'with missing parameters' do
      it 'returns error for missing email' do
        post '/users/sign_in', params: { user: { password: 'password123' } }, as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Invalid credentials')
      end

      it 'returns error for missing password' do
        post '/users/sign_in', params: { user: { email: user.email } }, as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Invalid credentials')
      end
    end
  end

  describe 'DELETE /users/sign_out' do
    context 'with valid authentication token' do
      let!(:user_with_token) { create(:user, :with_token) }
      let(:token) { user_with_token.authentication_token }
      let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

      it 'successfully logs out user and invalidates token' do
        expect(user_with_token.authentication_token).to be_present # Verify token exists

        delete '/users/sign_out', headers: auth_headers

        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Signed out successfully')
        
        # Verify token is invalidated
        user_with_token.reload
        expect(user_with_token.authentication_token).to be_nil
      end
    end

    context 'with invalid authentication token' do
      let(:invalid_headers) { { 'Authorization' => 'Bearer invalid_token' } }

      it 'returns unauthorized error' do
        delete '/users/sign_out', headers: invalid_headers

        expect(response).to have_http_status(:unauthorized)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end

    context 'without authentication token' do
      it 'returns unauthorized error' do
        delete '/users/sign_out'

        expect(response).to have_http_status(:unauthorized)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
  end
end
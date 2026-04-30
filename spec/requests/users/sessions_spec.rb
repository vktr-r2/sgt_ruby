require 'rails_helper'

RSpec.describe 'Users::Sessions', type: :request do
  include ActiveSupport::Testing::TimeHelpers

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

        # Verify DB stores the hash of the returned plain token
        user.reload
        expect(user.authentication_token).to eq(Digest::SHA256.hexdigest(json_response['token']))
      end

      it 'resets failed attempts on successful login' do
        user.update!(failed_attempts: 3)

        post '/users/sign_in', params: login_params, as: :json

        expect(response).to have_http_status(:ok)
        user.reload
        expect(user.failed_attempts).to eq(0)
      end

      it 'tracks sign in information' do
        post '/users/sign_in', params: login_params, as: :json

        expect(response).to have_http_status(:ok)
        user.reload
        expect(user.sign_in_count).to eq(1)
        expect(user.current_sign_in_at).to be_present
        expect(user.current_sign_in_ip).to be_present
      end

      it 'updates last sign in on subsequent logins' do
        # First login
        post '/users/sign_in', params: login_params, as: :json
        user.reload
        first_sign_in = user.current_sign_in_at

        # Second login
        travel 1.hour do
          post '/users/sign_in', params: login_params, as: :json
          user.reload
          expect(user.sign_in_count).to eq(2)
          expect(user.last_sign_in_at).to eq(first_sign_in)
          expect(user.current_sign_in_at).to be > first_sign_in
        end
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

      it 'increments failed attempts' do
        post '/users/sign_in', params: invalid_params, as: :json

        user.reload
        expect(user.failed_attempts).to eq(1)
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

    context 'account lockout' do
      let(:invalid_params) do
        {
          user: {
            email: user.email,
            password: 'wrong_password'
          }
        }
      end

      it 'locks account after 5 failed attempts' do
        5.times do
          post '/users/sign_in', params: invalid_params, as: :json
        end

        user.reload
        expect(user.failed_attempts).to eq(5)
        expect(user.locked_at).to be_present
      end

      it 'returns 423 status for locked account' do
        user.update!(failed_attempts: 5, locked_at: Time.current)

        post '/users/sign_in', params: login_params, as: :json

        expect(response).to have_http_status(:locked)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Account locked. Try again in 15 minutes.')
      end

      it 'unlocks account after 15 minutes' do
        user.update!(failed_attempts: 5, locked_at: 16.minutes.ago)

        post '/users/sign_in', params: login_params, as: :json

        expect(response).to have_http_status(:ok)
        user.reload
        expect(user.failed_attempts).to eq(0)
        expect(user.locked_at).to be_nil
      end

      it 'does not increment failed attempts for non-existent user' do
        post '/users/sign_in', params: { user: { email: 'nonexistent@example.com', password: 'password' } }, as: :json

        expect(response).to have_http_status(:unauthorized)
        # No user exists to have failed attempts incremented
      end
    end
  end

  describe 'DELETE /users/sign_out' do
    context 'with valid authentication token' do
      let!(:user_with_token) { create(:user, :with_token) }
      let(:token) { user_with_token.plain_token }
      let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

      it 'successfully logs out user and invalidates token' do
        expect(user_with_token.authentication_token).to be_present # Verify hash is stored

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

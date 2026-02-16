# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users::Passwords', type: :request do
  let(:user) { create(:user, email: 'test@example.com', password: 'password123') }

  describe 'POST /users/password' do
    context 'with valid email' do
      it 'returns success message' do
        post '/users/password', params: { user: { email: user.email } }, as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Password reset instructions sent')
      end

      it 'sends password reset email' do
        expect {
          post '/users/password', params: { user: { email: user.email } }, as: :json
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it 'sets reset_password_token on user' do
        post '/users/password', params: { user: { email: user.email } }, as: :json

        user.reload
        expect(user.reset_password_token).to be_present
        expect(user.reset_password_sent_at).to be_present
      end
    end

    context 'with non-existent email' do
      it 'returns success message for security' do
        post '/users/password', params: { user: { email: 'nonexistent@example.com' } }, as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Password reset instructions sent')
      end

      it 'does not send email' do
        expect {
          post '/users/password', params: { user: { email: 'nonexistent@example.com' } }, as: :json
        }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context 'with missing email parameter' do
      it 'returns error message' do
        post '/users/password', params: { user: {} }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Email is required')
      end
    end
  end

  describe 'PUT /users/password' do
    let!(:reset_token) { user.send_reset_password_instructions }

    context 'with valid token and matching passwords' do
      it 'resets the password successfully' do
        put '/users/password', params: {
          user: {
            reset_password_token: reset_token,
            password: 'newpassword123',
            password_confirmation: 'newpassword123'
          }
        }, as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Password reset successfully')
      end

      it 'allows login with new password' do
        put '/users/password', params: {
          user: {
            reset_password_token: reset_token,
            password: 'newpassword123',
            password_confirmation: 'newpassword123'
          }
        }, as: :json

        user.reload
        expect(user.valid_password?('newpassword123')).to be true
        expect(user.valid_password?('password123')).to be false
      end

      it 'invalidates the reset token after use' do
        put '/users/password', params: {
          user: {
            reset_password_token: reset_token,
            password: 'newpassword123',
            password_confirmation: 'newpassword123'
          }
        }, as: :json

        user.reload
        expect(user.reset_password_token).to be_nil
      end
    end

    context 'with invalid token' do
      it 'returns error message' do
        put '/users/password', params: {
          user: {
            reset_password_token: 'invalid_token',
            password: 'newpassword123',
            password_confirmation: 'newpassword123'
          }
        }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Reset password token')
      end
    end

    context 'with expired token' do
      it 'returns error message' do
        # Set reset_password_sent_at to 25 hours ago (token expires in 24 hours)
        user.update_column(:reset_password_sent_at, 25.hours.ago)

        put '/users/password', params: {
          user: {
            reset_password_token: reset_token,
            password: 'newpassword123',
            password_confirmation: 'newpassword123'
          }
        }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Reset password token')
      end
    end

    context 'with mismatched passwords' do
      it 'returns error message' do
        put '/users/password', params: {
          user: {
            reset_password_token: reset_token,
            password: 'newpassword123',
            password_confirmation: 'differentpassword'
          }
        }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include("Password confirmation doesn't match")
      end
    end

    context 'with weak password' do
      it 'returns error message for password too short' do
        put '/users/password', params: {
          user: {
            reset_password_token: reset_token,
            password: '12345',
            password_confirmation: '12345'
          }
        }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Password')
      end
    end

    context 'with missing parameters' do
      it 'returns error for missing token' do
        put '/users/password', params: {
          user: {
            password: 'newpassword123',
            password_confirmation: 'newpassword123'
          }
        }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Reset password token')
      end
    end
  end
end

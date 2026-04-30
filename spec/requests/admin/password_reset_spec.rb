# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Password Reset Link Generation", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let!(:admin_user) { create(:user, :admin, :with_token) }
  let!(:regular_user) { create(:user, :with_token) }
  let!(:target_user) { create(:user, name: "John Smith", email: "john@example.com") }
  let(:admin_headers) { { "Authorization" => "Bearer #{admin_user.plain_token}" } }
  let(:regular_headers) { { "Authorization" => "Bearer #{regular_user.plain_token}" } }

  describe "POST /admin/users/:user_id/generate_reset_link" do
    context "when admin generates reset link" do
      it "returns success with reset link" do
        post "/admin/users/#{target_user.id}/generate_reset_link", headers: admin_headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["reset_link"]).to be_present
        expect(json["message"]).to eq("Password reset link generated. Valid for 24 hours.")
      end

      it "includes user info in response" do
        post "/admin/users/#{target_user.id}/generate_reset_link", headers: admin_headers

        json = JSON.parse(response.body)
        expect(json["user"]["id"]).to eq(target_user.id)
        expect(json["user"]["name"]).to eq("John Smith")
        expect(json["user"]["email"]).to eq("john@example.com")
      end

      it "includes reset_link with token parameter" do
        post "/admin/users/#{target_user.id}/generate_reset_link", headers: admin_headers

        json = JSON.parse(response.body)
        reset_link = json["reset_link"]
        expect(reset_link).to include("/reset-password?token=")
        expect(reset_link).to match(%r{http://localhost:3000/reset-password\?token=.+})
      end

      it "sets reset_password_token on user" do
        expect {
          post "/admin/users/#{target_user.id}/generate_reset_link", headers: admin_headers
        }.to change { target_user.reload.reset_password_token }.from(nil)

        expect(target_user.reset_password_token).to be_present
      end

      it "sets reset_password_sent_at timestamp" do
        freeze_time do
          post "/admin/users/#{target_user.id}/generate_reset_link", headers: admin_headers

          target_user.reload
          expect(target_user.reset_password_sent_at).to be_within(1.second).of(Time.current)
        end
      end

      it "includes expires_at timestamp in response" do
        freeze_time do
          post "/admin/users/#{target_user.id}/generate_reset_link", headers: admin_headers

          json = JSON.parse(response.body)
          expires_at = Time.parse(json["expires_at"])
          expect(expires_at).to be_within(1.second).of(24.hours.from_now)
        end
      end

      it "does not send email" do
        expect {
          post "/admin/users/#{target_user.id}/generate_reset_link", headers: admin_headers
        }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context "when generated token is used to reset password" do
      it "allows password reset with the generated token" do
        post "/admin/users/#{target_user.id}/generate_reset_link", headers: admin_headers
        json = JSON.parse(response.body)

        # Extract raw token from URL
        reset_link = json["reset_link"]
        raw_token = reset_link.split("token=").last

        # Use the token to reset password
        put "/users/password", params: {
          user: {
            reset_password_token: raw_token,
            password: "new_secure_password123",
            password_confirmation: "new_secure_password123"
          }
        }

        expect(response).to have_http_status(:ok)
        target_user.reload
        expect(target_user.valid_password?("new_secure_password123")).to be true
      end
    end

    context "when token expires" do
      it "rejects password reset after 24 hours" do
        post "/admin/users/#{target_user.id}/generate_reset_link", headers: admin_headers
        json = JSON.parse(response.body)
        raw_token = json["reset_link"].split("token=").last

        travel_to(25.hours.from_now) do
          put "/users/password", params: {
            user: {
              reset_password_token: raw_token,
              password: "new_secure_password123",
              password_confirmation: "new_secure_password123"
            }
          }

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json["error"]).to include("expired")
        end
      end
    end

    context "when user is not found" do
      it "returns 404 not found" do
        post "/admin/users/99999/generate_reset_link", headers: admin_headers

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("User not found")
      end
    end

    context "when regular user tries to generate link" do
      it "returns 403 forbidden" do
        post "/admin/users/#{target_user.id}/generate_reset_link", headers: regular_headers

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Admin access required")
      end
    end

    context "when unauthenticated" do
      it "returns 401 unauthorized" do
        post "/admin/users/#{target_user.id}/generate_reset_link"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

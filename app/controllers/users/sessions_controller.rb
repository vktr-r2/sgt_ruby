# frozen_string_literal: true

class Users::SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :create ]

  def create
    user = User.find_by(email: sign_in_params[:email])

    # Check if account is locked
    if user&.access_locked?
      render json: { error: "Account locked. Try again in 15 minutes." }, status: :locked
      return
    end

    # Unlock account if lock period has passed
    if user&.locked_at.present? && user.locked_at < 15.minutes.ago
      user.unlock_access!
    end

    if user&.valid_password?(sign_in_params[:password])
      # Reset failed attempts and track sign in
      user.failed_attempts = 0
      user.last_sign_in_at = user.current_sign_in_at
      user.last_sign_in_ip = user.current_sign_in_ip
      user.current_sign_in_at = Time.current
      user.current_sign_in_ip = request.remote_ip
      user.sign_in_count += 1
      user.save!

      user.rotate_authentication_token!
      render json: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          admin: user.admin
        },
        token: user.plain_token
      }
    else
      # Increment failed attempts (if user exists)
      if user
        user.failed_attempts += 1
        user.locked_at = Time.current if user.failed_attempts >= 5
        user.save!
      end

      render json: { error: "Invalid credentials" }, status: :unauthorized
    end
  end

  def destroy
    token = request.headers["Authorization"]&.split(" ")&.last
    user = User.find_by_token(token)

    if user
      user.update_column(:authentication_token, nil)
      render json: { message: "Signed out successfully" }
    else
      render json: { error: "Not signed in" }, status: :unauthorized
    end
  end

  private

  def sign_in_params
    params.require(:user).permit(:email, :password)
  end
end

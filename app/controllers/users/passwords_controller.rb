# frozen_string_literal: true

class Users::PasswordsController < ApplicationController
  skip_before_action :authenticate_user!

  # POST /users/password
  # Request password reset - sends email with reset instructions
  def create
    user_params = params[:user] || {}
    email = user_params[:email]

    if email.blank?
      return render json: { error: "Email is required" }, status: :unprocessable_entity
    end

    user = User.find_by(email: email)

    if user
      begin
        user.send_reset_password_instructions
      rescue StandardError => e
        Rails.logger.error "Password reset email failed: #{e.class} - #{e.message}"
        # In production, still return success for security, but log the error
        return render json: { message: "Password reset instructions sent" }
      end
    end

    # Always return success for security (don't reveal if email exists)
    render json: { message: "Password reset instructions sent" }
  end

  # PUT /users/password
  # Reset password with token
  def update
    user = User.reset_password_by_token(reset_password_params)

    if user.errors.empty?
      render json: { message: "Password reset successfully" }
    else
      render json: { error: user.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:user).permit(:email)
  end

  def reset_password_params
    params.require(:user).permit(:reset_password_token, :password, :password_confirmation)
  end
end

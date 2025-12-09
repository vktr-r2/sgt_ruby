# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :authenticate_user!, only: [ :create ]

  def create
    user = User.new(sign_up_params)

    if user.save
      user.ensure_authentication_token!
      render json: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          admin: user.admin
        },
        token: user.authentication_token
      }, status: :created
    else
      render json: { error: user.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def show
    render json: {
      user: {
        id: current_user.id,
        email: current_user.email,
        name: current_user.name,
        admin: current_user.admin
      }
    }
  end

  private

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :name)
  end
end

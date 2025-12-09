module Api
  class AuthController < Api::BaseController
    skip_before_action :authenticate_api_user!, only: [ :login, :register ]

    def login
      user = User.find_by(email: params[:email])

      if user&.valid_password?(params[:password])
        user.ensure_authentication_token!
        render_success({
          user: user_data(user),
          token: user.authentication_token
        })
      else
        render_error("Invalid credentials", :unauthorized)
      end
    end

    def register
      user = User.new(user_params)

      if user.save
        user.ensure_authentication_token!
        render_success({
          user: user_data(user),
          token: user.authentication_token
        })
      else
        render_error(user.errors.full_messages.join(", "), :unprocessable_entity)
      end
    end

    def me
      render_success({ user: user_data(current_api_user) })
    end

    private

    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation, :name)
    end

    def user_data(user)
      {
        id: user.id,
        email: user.email,
        name: user.name
      }
    end
  end
end

# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  skip_before_action :authenticate_user!
  
  def create
    user = User.find_by(email: sign_in_params[:email])
    
    if user&.valid_password?(sign_in_params[:password])
      user.ensure_authentication_token!
      render json: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          admin: user.admin
        },
        token: user.authentication_token
      }
    else
      render json: { error: 'Invalid credentials' }, status: :unauthorized
    end
  end
  
  def destroy
    if current_user
      current_user.update(authentication_token: nil)
      render json: { message: 'Signed out successfully' }
    else
      render json: { error: 'Not signed in' }, status: :unauthorized
    end
  end
  
  private
  
  def sign_in_params
    params.require(:user).permit(:email, :password)
  end
end

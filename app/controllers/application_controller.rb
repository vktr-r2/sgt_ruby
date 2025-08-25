class ApplicationController < ActionController::API
  include ActionController::Cookies
  include Devise::Controllers::Helpers
  
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  private
  
  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
    return render json: { error: 'Unauthorized' }, status: :unauthorized unless token
    
    @current_user = User.find_by(authentication_token: token)
    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
  end
  
  def current_user
    @current_user
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end
end

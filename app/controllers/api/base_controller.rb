module Api
  class BaseController < ApplicationController
    before_action :authenticate_api_user!

    private

    def authenticate_api_user!
      token = request.headers["Authorization"]&.sub(/^Bearer /, "")

      if token.present?
        @current_api_user = User.find_by(authentication_token: token)
        render_error("Invalid token", :unauthorized) unless @current_api_user
      else
        render_error("Authorization token required", :unauthorized)
      end
    end

    def current_api_user
      @current_api_user
    end

    def render_success(data = {}, status = :ok)
      render json: {
        success: true,
        data: data
      }, status: status
    end

    def render_error(message, status = :bad_request)
      render json: {
        success: false,
        error: message
      }, status: status
    end
  end
end

module Draft
  class DraftController < ApplicationController
    before_action :authenticate_user!
    def pick
      @golfers = DraftHelper::GolferData.get_current_tourn_golfers
      @user = current_user
      return @golfers, @user
    end

    def submit
      @user = current_user
    end

    def review
    end
  end
end

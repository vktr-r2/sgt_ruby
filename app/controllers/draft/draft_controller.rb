module Draft
  class DraftController < ApplicationController
    def pick
      @golfers = DraftHelper::GolferData.get_current_tourn_golfers
      @sorted_golfers = DraftHelper::GolferData.sort_current_tourn_golfers(@golfers)
      @sorted_golfers
    end

    def submit
    end

    def review
    end
  end
end

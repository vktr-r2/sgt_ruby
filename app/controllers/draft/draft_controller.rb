module Draft
  class DraftController < ApplicationController
    before_action :authenticate_user!, :load_golfers, :load_draft_review_data
    before_action :load_tournament, only: [ :submit ]

    def index
      current_time = Time.zone.now

      # Handle cases where its Monday (not time to draft yet) or tournament golfers not avail in DB.
      if @golfers.blank?
        @mode = :unavailable

      # Handle draft day cases
      elsif (current_time.tuesday? || current_time.wednesday?) && picks.empty?
        @mode = :pick

      # Handle reviewing your existing picks any other time.
      else
        @mode = :review
      end

      render "draft"
    end

    def submit
      tournament_id = tournament.id
      # Process each golfer selection
      8.times do |i|
        golfer_id = params["golfer_p#{i+1}"]

        # Only create record if a golfer was selected
        if golfer_id.present?
          MatchPick.create!(
            user_id: current_user.id,
            tournament_id: tournament_id,
            golfer_id: golfer_id,
            priority: i + 1
          )
        end
      end

      redirect_to draft_review_path, notice: "Picks submitted successfully!"
    rescue StandardError => e
      redirect_to draft_pick_path, alert: "Error submitting picks. Please try again."
    end

    private
    def load_golfers
      @golfers = BusinessLogic::GolferService.new.get_current_tourn_golfers
    end

    def load_draft_review_data
      @data = BusinessLogic::DraftService.new(current_user).get_draft_review_data
    end

    def load_tournament
      @tournament = BusinessLogic::TournamentService.current_tournament
    end
  end
end

# Setup draft view to check if picks for user+tournament combo already exist, if so redirect to review
# Setup a job to check on Wednesday midnight to ensure picks have been made - if not then randomize picks

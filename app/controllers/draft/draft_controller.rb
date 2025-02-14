module Draft
  class DraftController < ApplicationController
    before_action :authenticate_user!
    def pick
      @golfers = DraftHelper::GolferData.get_current_tourn_golfers
      @golfers
    end

    def submit
      tournament = ApplicationHelper::TournamentEvaluations.determine_current_tournament
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

    def review
      tournament = ApplicationHelper::TournamentEvaluations.determine_current_tournament
      golfers = DraftHelper::PickData.get_users_picks_for_tourn(current_user.id)
      @data = {
        tournament_name: tournament.name,
        year: Date.today.year,
        picks: golfers
      }
    end
  end
end

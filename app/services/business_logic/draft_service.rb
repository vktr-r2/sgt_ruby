module BusinessLogic
  class DraftService
    def initialize(current_user)
      @current_tournament = BusinessLogic::TournamentService.new.current_tournament
      @user_service = BusinessLogic::UserService.new
      @current_tourn_golfers = BusinessLogic::GolferService.new.get_current_tourn_golfers
      @current_user = current_user
    end

    def get_current_user_picks_for_tourn
      picks = MatchPick.where(
        user_id: @current_user.id,
        tournament_id: @current_tournament.id
        )
      picks || []
    end

    def get_draft_review_data
      {
        tournament_name: @current_tournament.name,
        year: Date.today.year,
        picks: get_current_user_picks_for_tourn
      }
    end

    def validate_picks
      user_ids = @user_service.get_user_ids
      user_ids.each do |user_id|
        validate_user_picks(user_id)
      end
    end

    private
    def validate_user_picks(user_id)
      current_picks = get_user_picks_for_tourn(user_id)
      if current_picks.blank?
        create_random_picks_for_user(user_id, current_picks)
      end
    end

    def create_random_picks_for_user(user_id, current_picks)
      8.times do |i|
        random_golfer = random_pick(current_picks)
        current_picks << random_golfer
        create_match_pick(user_id, random_golfer.id, i + 1)
      end
    end

    def create_match_pick(user_id, golfer_id, priority)
      MatchPick.create!(
        user_id: user_id,
        tournament_id: @current_tournament.id,
        golfer_id: golfer_id,
        priority: priority
      )
    end

    def get_user_picks_for_tourn(user_id)
      picks = MatchPick.where(
        user_id: user_id,
        tournament_id: @current_tournament.id
      )
      picks.to_a || []
    end

    def random_pick(current_picks)
      random_golfer = @current_tourn_golfers.sample
      while is_pick_dupe?(current_picks, random_golfer)
        random_golfer = @current_tourn_golfers.sample
      end
      random_golfer
    end

    def is_pick_dupe?(current_picks, golfer_pick)
      current_picks.include?(golfer_pick)
    end
  end
end

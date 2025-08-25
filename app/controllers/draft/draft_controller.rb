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
      elsif (current_time.tuesday? || current_time.wednesday?) && @data[:picks].blank?
        @mode = :pick

      # Handle reviewing your existing picks any other time.
      else
        @mode = :review
      end

      render json: {
        mode: @mode,
        golfers: @golfers.map { |g| golfer_json(g) },
        tournament: tournament_json(@data),
        picks: @data[:picks].map { |p| pick_json(p) }
      }
    end

    def submit
      tournament_id = @tournament.id
      picks_data = params[:picks] || []
      
      # Clear existing picks first
      MatchPick.where(user_id: current_user.id, tournament_id: tournament_id).destroy_all
      
      # Process each golfer selection
      picks_data.each_with_index do |pick, index|
        golfer_id = pick[:golfer_id] || pick["golfer_id"]
        
        if golfer_id.present?
          MatchPick.create!(
            user_id: current_user.id,
            tournament_id: tournament_id,
            golfer_id: golfer_id,
            priority: index + 1
          )
        end
      end

      render json: { message: "Picks submitted successfully!" }
    rescue StandardError => e
      render json: { error: "Error submitting picks: #{e.message}" }, status: :unprocessable_entity
    end

    private
    def load_golfers
      @golfers = BusinessLogic::GolferService.new.get_current_tourn_golfers
    end

    def load_draft_review_data
      @data = BusinessLogic::DraftService.new(current_user).get_draft_review_data
    end

    def load_tournament
      @tournament = BusinessLogic::TournamentService.new.current_tournament
    end
    
    private
    
    def golfer_json(golfer)
      {
        id: golfer.id,
        first_name: golfer.first_name,
        last_name: golfer.last_name,
        full_name: "#{golfer.first_name} #{golfer.last_name}"
      }
    end
    
    def tournament_json(data)
      {
        name: data[:tournament_name],
        year: data[:year]
      }
    end
    
    def pick_json(pick)
      {
        id: pick.id,
        golfer_id: pick.golfer_id,
        priority: pick.priority
      }
    end
  end
end

module BusinessLogic
  class DraftWindowService
    def initialize(tournament = nil)
      @tournament = tournament || BusinessLogic::TournamentService.new.current_tournament
    end

    def draft_open?
      return false unless @tournament
      @tournament.draft_window_open?
    end

    def draft_window_status
      return :no_tournament unless @tournament
      
      current_time = Time.zone.now
      
      if current_time < @tournament.draft_window_start
        :before_window
      elsif current_time > @tournament.draft_window_end
        :after_window
      else
        :open
      end
    end

    def time_until_draft_opens
      return nil unless @tournament
      [@tournament.draft_window_start - Time.zone.now, 0].max
    end

    def time_until_draft_closes
      return nil unless @tournament
      [@tournament.draft_window_end - Time.zone.now, 0].max
    end
  end
end
module BusinessLogic
  class ScheduleService
    attr_reader :season_start_date, :season_end_date
    def initialize(schedule_data)
      @season_start_date = Date.new(Date.current.year, 1, 1)
      @season_end_date = determine_tour_championship_end_date(schedule_data)
    end

    def determine_tour_championship_end_date(schedule_data)
      schedule_data["schedule"].each do |tournament|
        if tournament["name"] == "TOUR Championship"
          return ApplicationHelper::DateOperations.date_hash_to_time_obj(tournament["date"]["end"]) + 2.day
        end
      end
      # Fallback: return end of current year if TOUR Championship not found
      Date.new(Date.current.year, 12, 31)
    end
  end
end
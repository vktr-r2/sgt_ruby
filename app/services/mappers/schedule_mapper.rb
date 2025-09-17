module Mappers
  class ScheduleMapper
    include ApplicationHelper::DateOperations

    def initialize(sched_data)
      @sched_data = sched_data
    end

    def map_to_attributes
      {
        # Basic tournament identification
        "tournament_id" => @sched_data["tournId"],
        "name" => @sched_data["name"],
        
        # Tournament scheduling
        "start_date" => start_date,
        "end_date" => end_date,
        "week_number" => week_number,
        "year" => tournament_year,
        
        # Tournament format
        "format" => @sched_data["format"]
      }
    end

    private

    def start_date
      ApplicationHelper::DateOperations.date_hash_to_time_obj(@sched_data["date"]["start"])
    end

    def end_date
      ApplicationHelper::DateOperations.date_hash_to_time_obj(@sched_data["date"]["end"])
    end

    def week_number
      @sched_data["date"]["weekNumber"]
    end

    def tournament_year
      ApplicationHelper::DateOperations.extract_year_from_date_hash(@sched_data["date"]["start"])
    end
  end
end

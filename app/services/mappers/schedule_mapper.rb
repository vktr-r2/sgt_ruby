module Mappers
  class ScheduleMapper
    include ApplicationHelper::DateOperations
    def initialize(sched_data)
      @sched_data = sched_data
    end

    def map_to_attributes
      {
        "tournament_id" => @sched_data["tournId"],
        "name" => @sched_data["name"],
        "start_date" => ApplicationHelper::DateOperations.date_hash_to_time_obj(@sched_data["date"]["start"]),
        "end_date" => ApplicationHelper::DateOperations.date_hash_to_time_obj(@sched_data["date"]["end"]),
        "week_number" => @sched_data["date"]["weekNumber"],
        "year" => ApplicationHelper::DateOperations.extract_year_from_date_hash(@sched_data["date"]["start"]),
        "format" => @sched_data["format"]
      }
    end
  end
end

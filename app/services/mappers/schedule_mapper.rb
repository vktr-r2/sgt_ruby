module Mappers
  class ScheduleMapper
    def initialize(sched_data)
      @sched_data = sched_data
    end

    def map_to_attributes
      @sched_data[:schedule].each do |sched_tourn|
        {
          "tournament_id" => sched_tourn["tournId"],
          "name" => sched_tourn["name"],
          "start_date" => sched_tourn["date"]["start"],
          "end_date" => sched_tourn["date"]["end"],
          "week_number" => sched_tourn["date"]["weekNumber"],
          "year" => Date.parse(sched_tourn["date"]["start"]).year,
          "format" => sched_tourn["format"]
        }
      end
    end
  end
end

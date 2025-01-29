module Mappers
  class TournamentMapper
    def initialize(tourn_data)
      @tourn_data = tourn_data
    end

    def map_to_attributes
      {
        "tournament_id" => @tourn_data["tournId"],
        "year" => ApplicationHelper::DateOperations.extract_year_from_date_hash(@tourn_data["date"]["start"]),
        "source_id" => @tourn_data.dig("_id", "$oid"),
        "golf_course" => @tourn_data["courses"][0]["courseName"],
        "location" => @tourn_data["courses"][0]["location"].to_json,
        "time_zone" => @tourn_data["timeZone"],
        "format" => @tourn_data["format"],
        "major_championship" => ApplicationHelper::TournamentEvaluations.is_major?(@tourn_data["name"]),
        "par" => @tourn_data["courses"][0]["parTotal"]
      }
    end
  end
end

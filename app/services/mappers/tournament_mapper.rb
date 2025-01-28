module Mappers
  class TournamentMapper
    def map_to_attributes
      {
        "source_id" => @tourn_data.dig("_id", "$oid"),
        "golf_course" => @tourn_data["courses"][0]["courseName"],
        "location" => @tourn_data["courses"][0]["location"].to_json,
        "timezone" => @tourn_data["timeZone"],
        "format" => @tourn_data["format"],
        "major_championship" => ApplicationHelper::DataEvaluations.is_major?(@tourn_data["name"]),
        "par" => @tourn_data["courses"][0]["parTotal"]
      }
    end
  end
end

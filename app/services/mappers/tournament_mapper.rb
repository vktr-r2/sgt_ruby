
module Mappers
  class TournamentMapper
    def initialize(tourn_data)
      @tourn_data = tourn_data
      @tournament_service = BusinessLogic::TournamentService.new
    end

    def map_to_attributes
      {
        # Unique identifier combining year and tournament ID
        "unique_id" => generate_unique_id,
        
        # Basic tournament information
        "tournament_id" => @tourn_data["tournId"],
        "year" => extract_year,
        
        # Course and location details
        "golf_course" => course_name,
        "location" => location_data,
        "time_zone" => @tourn_data["timeZone"],
        
        # Tournament format and classification
        "format" => @tourn_data["format"],
        "major_championship" => major_championship?,
        
        # Course specifications
        "par" => course_par,
        "purse" => purse_amount
      }
    end

    private

    def generate_unique_id
      "#{extract_year}#{@tourn_data["tournId"]}".to_i
    end

    def extract_year
      ApplicationHelper::DateOperations.extract_year_from_date_hash(@tourn_data["date"]["start"])
    end

    def course_name
      @tourn_data["courses"][0]["courseName"]
    end

    def location_data
      @tourn_data["courses"][0]["location"].to_json
    end

    def major_championship?
      @tournament_service.is_major?(@tourn_data["name"])
    end

    def course_par
      @tourn_data["courses"][0]["parTotal"]
    end

    def purse_amount
      @tourn_data["purse"]["$numberInt"].to_i
    end
  end
end

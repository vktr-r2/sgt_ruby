module Mappers
  class GolferMapper
    def initialize(golfer_data, tournament_unique_id)
      @golfer_data = golfer_data
      @tournament_unique_id = tournament_unique_id
    end

    def map_to_attributes
      {
        "source_id" => @golfer_data["playerId"],
        "f_name" => @golfer_data["firstName"],
        "l_name" => @golfer_data["lastName"],
        "last_active_tourney" => @tournament_unique_id
      }
    end
  end
end

module Mappers
  class GolferMapper
    def initialize(golfer_data, tournament_unique_id)
      @golfer_data = golfer_data
      @tournament_unique_id = tournament_unique_id
    end

    def map_to_attributes
      {
        # Golfer identification
        "source_id" => player_id,
        
        # Golfer name information
        "f_name" => first_name,
        "l_name" => last_name,
        
        # Tournament association
        "last_active_tourney" => @tournament_unique_id
      }
    end

    private

    def player_id
      @golfer_data["playerId"]
    end

    def first_name
      @golfer_data["firstName"]
    end

    def last_name
      @golfer_data["lastName"]
    end
  end
end

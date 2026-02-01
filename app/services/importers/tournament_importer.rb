module Importers
  # TournamentImporter takes tournament api data and imports into both tournaments and golfers tables
  class TournamentImporter
    def initialize(tourn_data)
      @tourn_data = tourn_data
    end

    def process
      # Map and save tournament
      mapped_tournament = Mappers::TournamentMapper.new(@tourn_data).map_to_attributes
      save_tournament(mapped_tournament)

      # Extract tournament_unique_id (tournId-year format)
      tournament_unique_id = mapped_tournament["unique_id"]

      # Loop through golfers array, map and save golfer
      @tourn_data["players"].each do |golfer|
        mapped_golfer = Mappers::GolferMapper.new(golfer, tournament_unique_id).map_to_attributes
        save_golfer(mapped_golfer)
      end
    end

    private
    def save_tournament(attributes)
      tournament = Tournament.find_by(tournament_id: attributes["tournament_id"],
                                      year: attributes["year"])
      tournament.assign_attributes(attributes)

      begin
        if tournament.save
          Rails.logger.info "#{tournament.name} saved successfully."
        else
          Rails.logger.error "Validation failed for tournament from tournament import: #{tournament.errors.full_messages.join(', ')}"
        end
      rescue StandardError => e
        Rails.logger.error "An unexpected error occurred while saving tournament from schedule import: #{e.message}"
      end
    end

    def save_golfer(attributes)
      golfer = Golfer.find_or_initialize_by(source_id: attributes["source_id"])
      golfer.assign_attributes(attributes)

      begin
        if golfer.save
          Rails.logger.info "#{golfer.source_id} saved successfully."
        else
          Rails.logger.error "Validation failed for tournament from tournament import: #{golfer.errors.full_messages.join(', ')}"
        end
      rescue StandardError => e
        Rails.logger.error "An unexpected error occurred while saving player data from tournament import: #{e.message}"
      end
    end
  end
end

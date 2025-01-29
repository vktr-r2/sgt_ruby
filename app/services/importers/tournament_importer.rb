module Importers
  class TournamentImporter
    def initialize(tourn_data)
      @tourn_data = tourn_data
    end

    def process
      mapped_data = Mappers::TournamentMapper.new(@tourn_data).map_to_attributes
      # binding.pry
      save_tournament(mapped_data)
    end

    private
    def save_tournament(attributes)
      tournament = Tournament.find_by(tournament_id: attributes["tournament_id"], year: attributes["year"])
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
  end
end

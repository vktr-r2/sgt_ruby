module Importers
  class ScheduleImporter
    def initialize(sched_data)
      @sched_data = sched_data
    end

    def process
      @sched_data["schedule"].each do |sched_tourn|
        mapped_data = Mappers::ScheduleMapper.new(sched_tourn).map_to_attributes
        save_schedule(mapped_data)
      end
    end

    private
    def save_schedule(attributes)
      tournament = Tournament.find_or_initialize_by(tournament_id: attributes[:tournament_id], year: attributes[:year])
      tournament.assign_attributes(attributes)



      begin
        if tournament.save
          Rails.logger.info "Tournament #{tournament.name} for year #{tournament.year} saved successfully."
        else
          Rails.logger.error "Validation failed for tournament from schedule import: #{tournament.errors.full_messages.join(', ')}"
        end
      rescue StandardError => e
        Rails.logger.error "An unexpected error occurred while saving tournament from schedule import: #{e.message}"
      end
    end
  end
end

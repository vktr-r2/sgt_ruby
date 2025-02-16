class ScheduleImportJob < ApplicationJob
  queue_as :default

  def initialize
    @api_data = RapidApi::ScheduleClient.new.fetch
  end

  def perform
    return nil if api_data.blank?
    Importers::ScheduleImporter.new(api_data).process
  end
end

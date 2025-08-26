class ScheduleImportJob < ApplicationJob
  queue_as :default

  def perform
    setup
    return nil if @api_data.blank?
    Importers::ScheduleImporter.new(@api_data).process
  end

  def setup
    @api_data = RapidApi::ScheduleClient.new.fetch
  end
end

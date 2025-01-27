class ScheduleImportJob < ApplicationJob
  queue_as :default

  def perform
    api_data = RapidApi::ScheduleClient.new.fetch
    nil if api_data.blank?

  Importers::ScheduleImporter.new(api_data).process
  end
end

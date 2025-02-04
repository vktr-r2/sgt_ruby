require "rails_helper"

RSpec.describe ScheduleImportJob, type: :job do
  let(:api_data) { [ { "tournament_id" => "123", "name" => "Test Tournament" } ] }
  let(:schedule_client) { instance_double(RapidApi::ScheduleClient, fetch: api_data) }
  let(:schedule_importer) { instance_double(Importers::ScheduleImporter, process: true) }

  before do
    allow(RapidApi::ScheduleClient).to receive(:new).and_return(schedule_client)
    allow(Importers::ScheduleImporter).to receive(:new).with(api_data).and_return(schedule_importer)
  end

  it "fetches API data and processes schedule import" do
    described_class.perform_now

    expect(schedule_client).to have_received(:fetch)
    expect(Importers::ScheduleImporter).to have_received(:new).with(api_data)
    expect(schedule_importer).to have_received(:process)
  end

  context "when API data is blank" do
    let(:api_data) { nil }

    it "does not process schedule import" do
      described_class.perform_now

      expect(schedule_client).to have_received(:fetch)
      expect(Importers::ScheduleImporter).not_to have_received(:new)
    end
  end
end

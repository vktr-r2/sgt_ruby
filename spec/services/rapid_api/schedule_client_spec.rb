require "rails_helper"

RSpec.describe RapidApi::ScheduleClient do
  subject(:client) { described_class.new }

  describe "#fetch" do
    let(:url_path) { "schedule" }
    let(:current_year) { Time.now.year }
    let(:params) { { org_id: 1, year: current_year } }
    let(:mock_response) { { "data" => "test schedule" } }

    before do
      # Mock the make_request method from BaseClient
      allow(client).to receive(:make_request).with(url_path, params).and_return(mock_response)
    end

    it "calls make_request with the correct URL path and parameters" do
      client.fetch
      expect(client).to have_received(:make_request).with(url_path, params)
    end

    it "returns the response from make_request" do
      result = client.fetch
      expect(result).to eq(mock_response)
    end
  end
end

require "rails_helper"

RSpec.describe RapidApi::TournamentClient do
  subject(:client) { described_class.new }

  describe "#fetch" do
    let(:url_path) { "tournament" }
    let(:year) { Time.now.year }
    let(:params) { { "orgId" => 1, "year" => year, "tournId" => 007 } }
    let(:mock_response) { { "data" => "test tournament data" } }

    before do
      allow(client).to receive(:make_request).with(url_path, params).and_return(mock_response)
    end

    it "calls make_request with the correct URL path and params" do
      client.fetch(007)
      expect(client).to have_received(:make_request).with(url_path, params)
    end

    it "returns the response from make_request" do
      result = client.fetch(007)
      expect(result).to eq(mock_response)
    end
  end
end

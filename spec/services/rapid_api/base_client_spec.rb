require "rails_helper"
require "webmock/rspec"

# Define test suite tied to RapidApi::BaseClient
RSpec.describe RapidApi::BaseClient do
  # described_class refers to RapidApi::BaseClient, :client is the instance of the class
  # This allows you to use client in the test cases instead of repeatedly creating a new instance.
  subject(:client) { described_class.new }

  # Defines group of tests related to make_request method
  # The '#' prefix indicates that make_request is an instance method (RSpec convention)
  describe "#make_request" do
    # "lazy-load" variables for the test
    # lazy-loaded means they are not evaluated until they are called in the test.
    let(:url_path) { "test-endpoint" }
    let(:params) { { key: "value" } }
    let(:base_url) { "https://live-golf-data.p.rapidapi.com/" }
    let(:default_headers) do
      {
        "X-RapidAPI-Key": "test-api-key",
        "X-RapidAPI-Host": "live-golf-data.p.rapidapi.com"
      }
    end

    # will run this code before each test in current scope
    before do
      allow(client).to receive(:base_url).and_return(base_url)
      allow(client).to receive(:default_headers).and_return(default_headers)
    end

    # context is used to describe different conditions or scenarios for the method being tested
    context "when the request is successful" do
      let(:response_body) { { "message" => "Success" }.to_json }
      let(:response_status) { 200 }

      # stub_request simulates HTTP call
      # .with ensures request headers and params are used
      # .to_return mocks the response
      before do
        stub_request(:get, "#{base_url}#{url_path}")
        .with(headers: default_headers, query: params)
        .to_return(status: response_status, body: response_body)
      end

      it "returns the parsed JSON response" do
        result = client.send(:make_request, url_path, params)
        expect(result).to eq({ "message" => "Success" })
      end
    end
  end
end

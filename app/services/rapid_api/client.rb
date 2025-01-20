require "faraday"

module RapidApi
  class Client
    def initialize(api_key = nil)
      @api_key = api_key || Rails.application.credentials.config[:rapid_api][:api_key]
      @base_url = "https://live-golf-data.p.rapidapi.com/"
      @headers = {
        "X-RapidAPI-Key": @api_key,  # Changed to @api_key instead of api_key
        "X-RapidAPI-Host": "live-golf-data.p.rapidapi.com"
      }
    end

    # private
    def make_request(url_path, params = {})
      connection = Faraday.new(url: @base_url) do |faraday|
        faraday.headers = @headers
      end

      begin
        # Make API request
        response = connection.get(url_path, params)

        # Check if response.status code in 200s range, if not log error
        unless response.success?
          Rails.logger.error "API request failed: #{response.status} - #{response.body}"
          return nil
        end

        # If successful, returned the parsed body
        JSON.parse(response.body)
      rescue Faraday::Error => e
        # Rescue any Faraday related errors
        Rails.logger.error "Error in make_request #{self.class.name}: #{e.message}"
        nil
      rescue JSON::ParserError => e
        # Rescure JSON parse errors
        Rails.logger.error "JSON parsing error in #{self.class.name}: #{e.message}"
        nil
      end
    end
  end
end

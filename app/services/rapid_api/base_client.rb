require "faraday"

module RapidApi
  class BaseClient
    private

    def make_request(url_path, params = {})
      # binding.pry
      connection = Faraday.new(url: base_url) do |faraday|
        faraday.headers = default_headers
        faraday.request :url_encoded # Ensure query parameters are encoded correctly
        # faraday.response :logger, Rails.logger # To enable logging
      end
      begin
        # Make the API request
        response = connection.get(url_path, params)
        handle_response(response)
      rescue Faraday::TimeoutError => e
        Rails.logger.error "API request timed out: #{e.message}"
        nil
      rescue Faraday::ConnectionFailed => e
        Rails.logger.error "Failed to connect to API: #{e.message}"
        nil
      rescue Faraday::Error => e
        Rails.logger.error "An error occurred during the API request: #{e.message}"
        nil
      end
    end

    def base_url
      "https://live-golf-data.p.rapidapi.com/"
    end

    def default_headers
      {
        "X-RapidAPI-Key": Rails.application.credentials.config[:rapid_api][:api_key],
        "X-RapidAPI-Host": "live-golf-data.p.rapidapi.com"
      }
    end

    def handle_response(response)
      if response.success?
        JSON.parse(response.body)
      else
        Rails.logger.error "API request failed: #{response.status} - #{response.body}"
        nil
      end
    end
  end
end

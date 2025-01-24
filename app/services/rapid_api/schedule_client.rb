module RapidApi
  class ScheduleClient < BaseClient
    def fetch
      url_path = "schedule"
      params = {
        org_id: 1,
        year: Time.now.year
      }
      make_request(url_path, params)
    end
  end
end

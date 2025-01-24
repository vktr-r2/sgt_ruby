module RapidApi
  class TournamentClient < BaseClient
    def fetch(tourn_id)
      url_path = "tournament"
      params = {
        "orgId" => 1,
        "tournId" => tourn_id,
        "year" => Time.now.year
      }
      make_request(url_path, params)
    end
  end
end

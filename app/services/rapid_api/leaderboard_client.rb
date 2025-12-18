module RapidApi
  class LeaderboardClient < BaseClient
    def fetch(tourn_id)
      url_path = "leaderboard"
      params = {
        "orgId" => 1,
        "tournId" => tourn_id,
        "year" => Time.now.year
      }
      make_request(url_path, params)
    end
  end
end

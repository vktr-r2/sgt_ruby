FactoryBot.define do
  factory :leaderboard_snapshot do
    association :tournament
    leaderboard_data { [{ "player_id" => "123", "name" => "Test Player", "position" => "1" }] }
    current_round { 1 }
    cut_line_score { nil }
    cut_line_count { nil }
    fetched_at { Time.current }
  end
end

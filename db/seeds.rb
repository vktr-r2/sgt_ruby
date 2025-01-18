require_relative "../lib/user_seed"
require_relative "../lib/golfer_seed"
require_relative "../lib/tournament_seed"
require_relative "../lib/match_picks_seed"
require_relative "../lib/score_seed"
require_relative "../lib/match_result_seed"

puts "Starting the seeding process..."
UserSeed.seed
GolferSeed.seed
TournamentSeed.seed
MatchPickSeed.seed
ScoreSeed.seed
MatchResultSeed.seed
puts "Seeding process completed!"

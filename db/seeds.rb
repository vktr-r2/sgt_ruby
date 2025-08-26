require_relative "../lib/test_user_seed"
require_relative "../lib/current_tournament_seed"

puts "Starting the test seeding process..."
TestUserSeed.seed
CurrentTournamentSeed.seed
puts "Test seeding process completed!"

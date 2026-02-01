require_relative "../lib/test_user_seed"
# require_relative "../lib/current_tournament_seed"

puts "Starting the seeding process..."
TestUserSeed.seed
# CurrentTournamentSeed.seed  # Commented out - real data comes from API
puts "Seeding process completed!"

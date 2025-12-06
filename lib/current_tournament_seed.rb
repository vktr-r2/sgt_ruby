class CurrentTournamentSeed
  def self.seed
    puts "Seeding current tournaments..."

    # Clear existing data
    Tournament.destroy_all
    Golfer.destroy_all
    MatchPick.destroy_all

    # Create current and upcoming tournaments for testing
    tournaments = [
      {
        name: "Past Championship 1",
        start_date: 3.weeks.ago,
        end_date: 3.weeks.ago + 3.days,
        week_number: 3.weeks.ago.strftime("%V").to_i,
        year: Date.current.year,
        format: "stroke",
        tournament_id: "past-championship-1-#{Date.current.year}",
        unique_id: "past-championship-1-#{Date.current.year}"
      },
      {
        name: "Past Championship 2",
        start_date: 2.weeks.ago,
        end_date: 2.weeks.ago + 3.days,
        week_number: 2.weeks.ago.strftime("%V").to_i,
        year: Date.current.year,
        format: "stroke",
        tournament_id: "past-championship-2-#{Date.current.year}",
        unique_id: "past-championship-2-#{Date.current.year}"
      },
      {
        name: "Past Championship 3",
        start_date: 1.week.ago,
        end_date: 4.days.ago,
        week_number: 1.week.ago.strftime("%V").to_i,
        year: Date.current.year,
        format: "stroke",
        tournament_id: "past-championship-3-#{Date.current.year}",
        unique_id: "past-championship-3-#{Date.current.year}"
      },
      {
        name: "Draft Window Open Tournament",
        start_date: Date.current + 2.days,
        end_date: Date.current + 5.days,
        week_number: (Date.current + 2.days).strftime("%V").to_i,
        year: Date.current.year,
        format: "stroke",
        tournament_id: "draft-window-open-#{Date.current.year}",
        unique_id: "draft-window-open-#{Date.current.year}"
      },
      {
        name: "Future Championship",
        start_date: 1.week.from_now,
        end_date: 1.week.from_now + 3.days,
        week_number: 1.week.from_now.strftime("%V").to_i,
        year: Date.current.year,
        format: "stroke",
        tournament_id: "future-championship-#{Date.current.year}",
        unique_id: "future-championship-#{Date.current.year}"
      }
    ]

    tournaments.each do |tournament_data|
      tournament = Tournament.create!(tournament_data)
      puts "Created tournament: #{tournament.name}"

      # Create golfers for each tournament
      golfers = [
        { f_name: "Tiger", l_name: "Woods" },
        { f_name: "Rory", l_name: "McIlroy" },
        { f_name: "Jon", l_name: "Rahm" },
        { f_name: "Scottie", l_name: "Scheffler" },
        { f_name: "Viktor", l_name: "Hovland" },
        { f_name: "Xander", l_name: "Schauffele" },
        { f_name: "Patrick", l_name: "Cantlay" },
        { f_name: "Dustin", l_name: "Johnson" },
        { f_name: "Brooks", l_name: "Koepka" },
        { f_name: "Bryson", l_name: "DeChambeau" },
        { f_name: "Justin", l_name: "Thomas" },
        { f_name: "Collin", l_name: "Morikawa" },
        { f_name: "Jordan", l_name: "Spieth" },
        { f_name: "Cameron", l_name: "Smith" },
        { f_name: "Joaquin", l_name: "Niemann" },
        { f_name: "Will", l_name: "Zalatoris" },
        { f_name: "Tony", l_name: "Finau" },
        { f_name: "Max", l_name: "Homa" },
        { f_name: "Sam", l_name: "Burns" },
        { f_name: "Hideki", l_name: "Matsuyama" }
      ]

      golfers.each_with_index do |golfer_data, index|
        golfer = Golfer.find_or_initialize_by(
          f_name: golfer_data[:f_name],
          l_name: golfer_data[:l_name]
        )
        # Only update last_active_tourney for the draft window open tournament
        if tournament.name == "Draft Window Open Tournament"
          golfer.last_active_tourney = tournament.unique_id
        end
        golfer.source_id ||= "seed-#{golfer_data[:f_name].downcase}-#{golfer_data[:l_name].downcase}-#{index + 1}"
        golfer.save!
      end

      puts "Created #{golfers.count} golfers for #{tournament.name}"
    end

    # Create match picks for user 1 (Scottie Scheffler in past tournaments for testing limit)
    create_test_match_picks

    puts "Tournament seeding completed!"
  end

  private

  def self.create_test_match_picks
    puts "Creating test match picks..."

    # Find Scottie Scheffler golfer
    scottie = Golfer.find_by(f_name: "Scottie", l_name: "Scheffler")
    return unless scottie

    # Find user 1 (first user in the system)
    user_1 = User.first
    return unless user_1

    # Find the three past tournaments
    past_tournaments = Tournament.where("name LIKE ?", "Past Championship%").order(:start_date)

    past_tournaments.each_with_index do |tournament, index|
      # Create picks for all 8 golfers
      all_golfers = [ scottie ] + Golfer.where.not(id: scottie.id).limit(7)

      all_golfers.each_with_index do |golfer, golfer_index|
        # Only first 2 picks (priorities 1 & 2) get drafted: true
        is_drafted = golfer_index < 2

        MatchPick.create!(
          user_id: user_1.id,
          tournament_id: tournament.id,
          golfer_id: golfer.id,
          priority: golfer_index + 1,
          drafted: is_drafted
        )
      end

      puts "Created 8 picks for user #{user_1.name} in #{tournament.name} (Scottie Scheffler priority 1, drafted: true)"
    end
  end
end

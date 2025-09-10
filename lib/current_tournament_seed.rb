class CurrentTournamentSeed
  def self.seed
    puts "Seeding current tournaments..."
    
    # Clear existing data
    Tournament.destroy_all
    Golfer.destroy_all
    
    # Create current and upcoming tournaments for testing
    tournaments = [
      {
        name: "Past Championship",
        start_date: 1.week.ago,
        end_date: 4.days.ago,
        week_number: 1.week.ago.strftime("%V").to_i,
        year: Date.current.year,
        format: "stroke",
        tournament_id: "past-championship-#{Date.current.year}",
        unique_id: "past-championship-#{Date.current.year}"
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
    
    puts "Tournament seeding completed!"
  end
end
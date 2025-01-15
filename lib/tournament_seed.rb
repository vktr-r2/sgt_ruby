class TournamentSeed < TableSeed
  def seed
    puts "Seeding tournaments..."
      tournament_data.each do |tourn|
        fields = tourn[:fields]

        Tournament.create!(
          tournament_id: fields[:tournament_id],
          source_id: fields[:source_id],
          name: fields[:name],
          year: fields[:year],
          golf_course: fields[:golf_course],
          location: fields[:location],
          par: fields[:par],
          start_date: fields[:start_date],
          end_date: fields[:end_date],
          week_number: fields[:week_number],
          time_zone: fields[:time_zone],
          format: fields[:format],
          major_championship: fields[:major_championship]
        )
      end
    puts "Tournaments seeded!"
  end

  private
  def tournament_data
    [
      {
        fields: {
          tournament_id: "001",
          source_id: "64fbe447235ac8857ff92842",
          name: "THE PLAYERS Championship",
          year: 2024,
          golf_course: "TPC Sawgrass (THE PLAYERS Stadium Course)",
          location: {
            city: "Tampa Bay",
            state: "Florida",
            country: "US"
          },
          par: 72,
          start_date: "2024-03-17T00:00:00Z",
          end_date: "2024-03-20T23:59:59Z",
          week_number: 10,
          time_zone: "America/New_York",
          format: "stroke",
          major_championship: false
        }
      },
      {
        fields: {
          tournament_id: "002",
          source_id: "54fbe447235ac8857ff92853",
          name: "The Masters Tournament",
          year: 2024,
          golf_course: "Augusta National Golf Club",
          location: {
            city: "Augusta",
            state: "Georgia",
            country: "US"
          },
          par: 72,
          start_date: "2024-04-06T00:00:00Z",
          end_date: "2024-04-09T23:59:59Z",
          week_number: 10,
          time_zone: "America/New_York",
          format: "Stroke",
          major_championship: true
        }
      }
    ]
  end
end

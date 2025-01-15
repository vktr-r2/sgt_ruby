class GolferSeed < TableSeed
  def seed
    puts "Seeding golfers..."
    golfer_data.each do |golfer_data|
      fields = golfer_data[:fields]

      Golfer.create!(
        source_id: fields[:source_id],
        f_name: fields[:f_name],
        l_name: fields[:l_name]
      )
    end
    puts "Golfers seeded!"
  end

  private

  def golfer_data
    [
      {
        fields: {
          source_id: "1000",
          f_name: "Tiger",
          l_name: "Woods"
        }
      },
      {
        fields: {
          source_id: "1001",
          f_name: "Rory",
          l_name: "McIlroy"
        }
      },
      {
        fields: {
          source_id: "1002",
          f_name: "Scottie",
          l_name: "Scheffler"
        }
      },
      {
        fields: {
          source_id: "1003",
          f_name: "Xander",
          l_name: "Schauffle"
        }
      },
      {
        fields: {
          source_id: "1004",
          f_name: "Viktor",
          l_name: "Hovland"
        }
      },
      {
        fields: {
          source_id: "1005",
          f_name: "Sungjae",
          l_name: "Im"
        }
      },
      {
        fields: {
          source_id: "1006",
          f_name: "Sahith",
          l_name: "Thegala"
        }
      },
      {
        fields: {
          source_id: "1007",
          f_name: "Hideki",
          l_name: "Matsuyama"
        }
      },
      {
        fields: {
          source_id: "1008",
          f_name: "Jordan",
          l_name: "Speith"
        }
      },
      {
        fields: {
          source_id: "1009",
          f_name: "Justin",
          l_name: "Thomas"
        }
      },
      {
        fields: {
          source_id: "1010",
          f_name: "Max",
          l_name: "Homa"
        }
      }
    ]
  end
end

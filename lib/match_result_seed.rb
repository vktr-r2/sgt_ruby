class MatchResultSeed < TableSeed
  def seed
    puts "Seeding match_results..."
      match_result_data.each do |result|
        fields = result[:fields]

        MatchResult.create!(
          tournament_id: fields[:tournament_id],
          user_id: fields[:user_id],
          total_score: fields[:total_score],
          place: fields[:place],
          winner_picked: fields[:winner_picked],
          cuts_missed: fields[:cuts_missed]
        )
      end
    puts "Results seeded!"
  end

  private
  def match_result_data
    [
      {
        fields: {
          tournament_id: 1,
          user_id: 1,
          total_score: 567,
          place: 1,
          winner_picked: true,
          cuts_missed: 0
        }
      },
      {
        fields: {
          tournament_id: 1,
          user_id: 2,
          total_score: 567,
          place: 2,
          winner_picked: false,
          cuts_missed: 0
        }
      },
      {
        fields: {
          tournament_id: 1,
          user_id: 3,
          total_score: 567,
          place: 3,
          winner_picked: false,
          cuts_missed: 1
        }
      },
      {
        fields: {
          tournament_id: 1,
          user_id: 4,
          total_score: 567,
          place: 4,
          winner_picked: false,
          cuts_missed: 2
        }
      }
    ]
  end
end

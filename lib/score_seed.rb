class ScoreSeed < TableSeed
  def seed
    puts "Seeding scores"
      score_data.each do |score|
        fields = score[:fields]

        Score.create!(
          match_pick_id: fields[:match_pick_id],
          score: fields[:score],
          round: fields[:round]
        )
      end
    puts "Scores seeded!"
  end

  private
  def score_data
    [
      {
        fields: {
          match_pick_id: 1,
          score: 72,
          round: 1
        }
      },
      {
        fields: {
          match_pick_id: 1,
          score: 72,
          round: 2
        }
      },
      {
        fields: {
          match_pick_id: 1,
          score: 72,
          round: 3
        }
      },
      {
        fields: {
          match_pick_id: 1,
          score: 72,
          round: 4
        }
      },
      {
        fields: {
          match_pick_id: 2,
          score: 72,
          round: 1
        }
      },
      {
        fields: {
          match_pick_id: 2,
          score: 72,
          round: 2
        }
      },
      {
        fields: {
          match_pick_id: 2,
          score: 72,
          round: 3
        }
      },
      {
        fields: {
          match_pick_id: 2,
          score: 72,
          round: 4
        }
      },
      {
        fields: {
          match_pick_id: 9,
          score: 72,
          round: 1
        }
      },
      {
        fields: {
          match_pick_id: 9,
          score: 72,
          round: 2
        }
      },
      {
        fields: {
          match_pick_id: 9,
          score: 72,
          round: 3
        }
      },
      {
        fields: {
          match_pick_id: 9,
          score: 72,
          round: 4
        }
      },
      {
        fields: {
          match_pick_id: 10,
          score: 72,
          round: 1
        }
      },
      {
        fields: {
          match_pick_id: 10,
          score: 72,
          round: 2
        }
      },
      {
        fields: {
          match_pick_id: 10,
          score: 72,
          round: 3
        }
      },
      {
        fields: {
          match_pick_id: 10,
          score: 72,
          round: 4
        }
      },
      {
        fields: {
          match_pick_id: 17,
          score: 72,
          round: 1
        }
      },
      {
        fields: {
          match_pick_id: 17,
          score: 72,
          round: 2
        }
      },
      {
        fields: {
          match_pick_id: 17,
          score: 72,
          round: 3
        }
      },
      {
        fields: {
          match_pick_id: 17,
          score: 72,
          round: 4
        }
      },
      {
        fields: {
          match_pick_id: 18,
          score: 72,
          round: 1
        }
      },
      {
        fields: {
          match_pick_id: 18,
          score: 72,
          round: 2
        }
      },
      {
        fields: {
          match_pick_id: 18,
          score: 72,
          round: 3
        }
      },
      {
        fields: {
          match_pick_id: 18,
          score: 72,
          round: 4
        }
      },
      {
        fields: {
          match_pick_id: 25,
          score: 72,
          round: 1
        }
      },
      {
        fields: {
          match_pick_id: 25,
          score: 72,
          round: 2
        }
      },
      {
        fields: {
          match_pick_id: 25,
          score: 72,
          round: 3
        }
      },
      {
        fields: {
          match_pick_id: 25,
          score: 72,
          round: 4
        }
      },
      {
        fields: {
          match_pick_id: 26,
          score: 72,
          round: 1
        }
      },
      {
        fields: {
          match_pick_id: 26,
          score: 72,
          round: 2
        }
      },
      {
        fields: {
          match_pick_id: 26,
          score: 72,
          round: 3
        }
      },
      {
        fields: {
          match_pick_id: 26,
          score: 72,
          round: 4
        }
      }
    ]
  end
end

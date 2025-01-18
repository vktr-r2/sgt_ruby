class MatchPickSeed < TableSeed
  def seed
    puts "Seeding match_picks..."
      match_pick_data.each do |pick|
        fields = pick[:fields]

        MatchPick.create!(
          user_id: fields[:user_id],
          tournament_id: fields[:tournament_id],
          golfer_id: fields[:golfer_id],
          priority: fields[:priority],
          drafted: fields[:drafted]
        )
      end
    puts "Picks seeded!"
  end

  private
  def match_pick_data
    [
  {
    fields: {
      user_id: 1,
      tournament_id: 1,
      golfer_id: 1,
      priority: 1,
      drafted: true
    }
  },
  {
    fields: {
      user_id: 1,
      tournament_id: 1,
      golfer_id: 2,
      priority: 2,
      drafted: true
    }
  },
  {
    fields: {
      user_id: 1,
      tournament_id: 1,
      golfer_id: 3,
      priority: 3,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 1,
      tournament_id: 1,
      golfer_id: 4,
      priority: 4,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 1,
      tournament_id: 1,
      golfer_id: 5,
      priority: 5,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 1,
      tournament_id: 1,
      golfer_id: 6,
      priority: 6,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 1,
      tournament_id: 1,
      golfer_id: 7,
      priority: 7,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 1,
      tournament_id: 1,
      golfer_id: 8,
      priority: 8,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 2,
      tournament_id: 1,
      golfer_id: 9,
      priority: 1,
      drafted: true
    }
  },
  {
    fields: {
      user_id: 2,
      tournament_id: 1,
      golfer_id: 10,
      priority: 2,
      drafted: true
    }
  },
  {
    fields: {
      user_id: 2,
      tournament_id: 1,
      golfer_id: 1,
      priority: 3,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 2,
      tournament_id: 1,
      golfer_id: 2,
      priority: 4,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 2,
      tournament_id: 1,
      golfer_id: 3,
      priority: 5,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 2,
      tournament_id: 1,
      golfer_id: 4,
      priority: 6,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 2,
      tournament_id: 1,
      golfer_id: 5,
      priority: 7,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 2,
      tournament_id: 1,
      golfer_id: 6,
      priority: 8,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 3,
      tournament_id: 1,
      golfer_id: 7,
      priority: 1,
      drafted: true
    }
  },
  {
    fields: {
      user_id: 3,
      tournament_id: 1,
      golfer_id: 8,
      priority: 2,
      drafted: true
    }
  },
  {
    fields: {
      user_id: 3,
      tournament_id: 1,
      golfer_id: 9,
      priority: 3,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 3,
      tournament_id: 1,
      golfer_id: 10,
      priority: 4,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 3,
      tournament_id: 1,
      golfer_id: 1,
      priority: 5,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 3,
      tournament_id: 1,
      golfer_id: 2,
      priority: 6,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 3,
      tournament_id: 1,
      golfer_id: 3,
      priority: 7,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 3,
      tournament_id: 1,
      golfer_id: 4,
      priority: 8,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 4,
      tournament_id: 1,
      golfer_id: 5,
      priority: 1,
      drafted: true
    }
  },
  {
    fields: {
      user_id: 4,
      tournament_id: 1,
      golfer_id: 6,
      priority: 2,
      drafted: true
    }
  },
  {
    fields: {
      user_id: 4,
      tournament_id: 1,
      golfer_id: 7,
      priority: 3,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 4,
      tournament_id: 1,
      golfer_id: 8,
      priority: 4,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 4,
      tournament_id: 1,
      golfer_id: 9,
      priority: 5,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 4,
      tournament_id: 1,
      golfer_id: 10,
      priority: 6,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 4,
      tournament_id: 1,
      golfer_id: 1,
      priority: 7,
      drafted: false
    }
  },
  {
    fields: {
      user_id: 4,
      tournament_id: 1,
      golfer_id: 2,
      priority: 8,
      drafted: false
    }
  }
]
  end
end

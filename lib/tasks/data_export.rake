# frozen_string_literal: true

namespace :data do
  desc "Export all data to CSV files for migration"
  task export: :environment do
    require "csv"

    export_dir = Rails.root.join("tmp/data_export/#{Date.current}")
    FileUtils.mkdir_p(export_dir)

    export_users(export_dir)
    export_tournaments(export_dir)
    export_golfers(export_dir)
    export_match_picks(export_dir)
    export_scores(export_dir)
    export_match_results(export_dir)

    puts "\n✅ Export complete!"
    puts "📁 Location: #{export_dir}"
    puts "\nTo import on another environment:"
    puts "  rails data:import[#{export_dir}]"
  end

  def export_users(dir)
    print "Exporting users..."
    CSV.open("#{dir}/users.csv", "w") do |csv|
      csv << %w[email name admin]
      User.find_each do |user|
        csv << [ user.email, user.name, user.admin ]
      end
    end
    puts " #{User.count} records"
  end

  def export_tournaments(dir)
    print "Exporting tournaments..."
    CSV.open("#{dir}/tournaments.csv", "w") do |csv|
      csv << %w[year week_number name start_date end_date golf_course major_championship par unique_id]
      Tournament.find_each do |t|
        csv << [
          t.year,
          t.week_number,
          t.name,
          t.start_date,
          t.end_date,
          t.golf_course,
          t.major_championship,
          t.par,
          t.unique_id
        ]
      end
    end
    puts " #{Tournament.count} records"
  end

  def export_golfers(dir)
    print "Exporting golfers..."
    CSV.open("#{dir}/golfers.csv", "w") do |csv|
      csv << %w[source_id f_name l_name]
      Golfer.find_each do |g|
        csv << [ g.source_id, g.f_name, g.l_name ]
      end
    end
    puts " #{Golfer.count} records"
  end

  def export_match_picks(dir)
    print "Exporting match_picks..."
    CSV.open("#{dir}/match_picks.csv", "w") do |csv|
      csv << %w[user_email year week_number golfer_source_id priority drafted original_golfer_source_id replaced_at_round replacement_reason]
      MatchPick.includes(:user, :golfer, :tournament).find_each do |mp|
        original_golfer = mp.original_golfer_id ? Golfer.find_by(id: mp.original_golfer_id) : nil
        csv << [
          mp.user.email,
          mp.tournament.year,
          mp.tournament.week_number,
          mp.golfer.source_id,
          mp.priority,
          mp.drafted,
          original_golfer&.source_id,
          mp.replaced_at_round,
          mp.replacement_reason
        ]
      end
    end
    puts " #{MatchPick.count} records"
  end

  def export_scores(dir)
    print "Exporting scores..."
    CSV.open("#{dir}/scores.csv", "w") do |csv|
      csv << %w[user_email year week_number golfer_source_id round score position status thru]
      Score.includes(match_pick: [ :user, :golfer, :tournament ]).find_each do |s|
        mp = s.match_pick
        csv << [
          mp.user.email,
          mp.tournament.year,
          mp.tournament.week_number,
          mp.golfer.source_id,
          s.round,
          s.score,
          s.position,
          s.status,
          s.thru
        ]
      end
    end
    puts " #{Score.count} records"
  end

  def export_match_results(dir)
    print "Exporting match_results..."
    CSV.open("#{dir}/match_results.csv", "w") do |csv|
      csv << %w[user_email year week_number total_score place winner_picked cuts_missed]
      MatchResult.includes(:user, :tournament).find_each do |mr|
        csv << [
          mr.user.email,
          mr.tournament.year,
          mr.tournament.week_number,
          mr.total_score,
          mr.place,
          mr.winner_picked,
          mr.cuts_missed
        ]
      end
    end
    puts " #{MatchResult.count} records"
  end
end

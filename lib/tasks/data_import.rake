# frozen_string_literal: true

namespace :data do
  desc "Import data from CSV files"
  task :import, [ :directory ] => :environment do |_t, args|
    require "csv"

    dir = args[:directory] || Rails.root.join("tmp/data_import")

    unless Dir.exist?(dir)
      puts "❌ Directory not found: #{dir}"
      exit 1
    end

    puts "📁 Importing from: #{dir}\n\n"

    ActiveRecord::Base.transaction do
      import_users(dir)
      import_tournaments(dir)
      import_golfers(dir)
      import_match_picks(dir)
      import_scores(dir)
      import_match_results(dir)
    end

    puts "\n✅ Import complete!"
  end

  def import_users(dir)
    file = "#{dir}/users.csv"
    return puts "⏭️  Skipping users (file not found)" unless File.exist?(file)

    print "Importing users..."
    count = 0
    CSV.foreach(file, headers: true) do |row|
      User.find_or_initialize_by(email: row["email"]).tap do |user|
        user.name = row["name"]
        user.admin = row["admin"] == "true"
        user.password = SecureRandom.hex(16) if user.new_record?
        user.save!
        count += 1
      end
    end
    puts " #{count} records"
  end

  def import_tournaments(dir)
    file = "#{dir}/tournaments.csv"
    return puts "⏭️  Skipping tournaments (file not found)" unless File.exist?(file)

    print "Importing tournaments..."
    count = 0
    CSV.foreach(file, headers: true) do |row|
      Tournament.find_or_initialize_by(
        year: row["year"].to_i,
        week_number: row["week_number"].to_i
      ).tap do |t|
        t.name = row["name"]
        t.start_date = row["start_date"]
        t.end_date = row["end_date"]
        t.golf_course = row["golf_course"]
        t.major_championship = row["major_championship"] == "true"
        t.par = row["par"].to_i if row["par"].present?
        t.unique_id = row["unique_id"]
        t.save!
        count += 1
      end
    end
    puts " #{count} records"
  end

  def import_golfers(dir)
    file = "#{dir}/golfers.csv"
    return puts "⏭️  Skipping golfers (file not found)" unless File.exist?(file)

    print "Importing golfers..."
    count = 0
    CSV.foreach(file, headers: true) do |row|
      Golfer.find_or_initialize_by(source_id: row["source_id"]).tap do |g|
        g.f_name = row["f_name"]
        g.l_name = row["l_name"]
        g.save!
        count += 1
      end
    end
    puts " #{count} records"
  end

  def import_match_picks(dir)
    file = "#{dir}/match_picks.csv"
    return puts "⏭️  Skipping match_picks (file not found)" unless File.exist?(file)

    print "Importing match_picks..."
    count = 0
    errors = 0
    CSV.foreach(file, headers: true) do |row|
      user = User.find_by(email: row["user_email"])
      tournament = Tournament.find_by(year: row["year"].to_i, week_number: row["week_number"].to_i)
      golfer = Golfer.find_by(source_id: row["golfer_source_id"])

      unless user && tournament && golfer
        errors += 1
        next
      end

      original_golfer = row["original_golfer_source_id"].present? ? Golfer.find_by(source_id: row["original_golfer_source_id"]) : nil

      MatchPick.find_or_initialize_by(
        user: user,
        tournament: tournament,
        golfer: golfer
      ).tap do |mp|
        mp.priority = row["priority"].to_i
        mp.drafted = row["drafted"] == "true"
        mp.original_golfer_id = original_golfer&.id
        mp.replaced_at_round = row["replaced_at_round"].present? ? row["replaced_at_round"].to_i : nil
        mp.replacement_reason = row["replacement_reason"]
        mp.save!
        count += 1
      end
    end
    puts " #{count} records" + (errors > 0 ? " (#{errors} skipped - missing references)" : "")
  end

  def import_scores(dir)
    file = "#{dir}/scores.csv"
    return puts "⏭️  Skipping scores (file not found)" unless File.exist?(file)

    print "Importing scores..."
    count = 0
    errors = 0
    CSV.foreach(file, headers: true) do |row|
      user = User.find_by(email: row["user_email"])
      tournament = Tournament.find_by(year: row["year"].to_i, week_number: row["week_number"].to_i)
      golfer = Golfer.find_by(source_id: row["golfer_source_id"])

      unless user && tournament && golfer
        errors += 1
        next
      end

      match_pick = MatchPick.find_by(user: user, tournament: tournament, golfer: golfer)
      unless match_pick
        errors += 1
        next
      end

      Score.find_or_initialize_by(
        match_pick: match_pick,
        round: row["round"].to_i
      ).tap do |s|
        s.score = row["score"].to_i
        s.position = row["position"]
        s.status = row["status"]
        s.thru = row["thru"]
        s.save!
        count += 1
      end
    end
    puts " #{count} records" + (errors > 0 ? " (#{errors} skipped - missing references)" : "")
  end

  def import_match_results(dir)
    file = "#{dir}/match_results.csv"
    return puts "⏭️  Skipping match_results (file not found)" unless File.exist?(file)

    print "Importing match_results..."
    count = 0
    errors = 0
    CSV.foreach(file, headers: true) do |row|
      user = User.find_by(email: row["user_email"])
      tournament = Tournament.find_by(year: row["year"].to_i, week_number: row["week_number"].to_i)

      unless user && tournament
        errors += 1
        next
      end

      MatchResult.find_or_initialize_by(
        user: user,
        tournament: tournament
      ).tap do |mr|
        mr.total_score = row["total_score"].to_i
        mr.place = row["place"].to_i
        mr.winner_picked = row["winner_picked"] == "true"
        mr.cuts_missed = row["cuts_missed"].to_i
        mr.save!
        count += 1
      end
    end
    puts " #{count} records" + (errors > 0 ? " (#{errors} skipped - missing references)" : "")
  end
end

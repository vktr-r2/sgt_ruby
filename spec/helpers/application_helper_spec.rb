require "rails_helper"

RSpec.describe ApplicationHelper do
  describe ApplicationHelper::DateOperations do
    describe ".date_hash_to_time_obj" do
      it "converts MongoDB date hash to Time object" do
        date_hash = { "$date" => { "$numberLong" => "1706832000000" } }  # Feb 1, 2024
        result = described_class.date_hash_to_time_obj(date_hash)

        expect(result).to be_a(Time)
        expect(result.to_i).to eq(1706832000)
      end
    end

    describe ".extract_year_from_date_hash" do
      it "extracts year from MongoDB date hash" do
        date_hash = { "$date" => { "$numberLong" => "1706832000000" } }  # Feb 1, 2024
        result = described_class.extract_year_from_date_hash(date_hash)

        expect(result).to eq(2024)
      end
    end
  end

  describe ApplicationHelper::TournamentEvaluations do
    describe ".is_major?" do
      it "returns true for major tournaments" do
        majors = [
          "Masters Tournament",
          "PGA Championship",
          "The Open Championship",
          "U.S. Open"
        ]

        majors.each do |major|
          expect(described_class.is_major?(major)).to be true
        end
      end

      it "returns false for non-major tournaments" do
        non_majors = [
          "The Players Championship",
          "BMW Championship",
          "Genesis Invitational"
        ]

        non_majors.each do |tournament|
          expect(described_class.is_major?(tournament)).to be false
        end
      end

      it "is case insensitive" do
        expect(described_class.is_major?("MASTERS TOURNAMENT")).to be true
        expect(described_class.is_major?("masters tournament")).to be true
      end
    end

    describe ".determine_current_tourn_id" do
      let(:current_week) { Date.today.strftime("%V").to_i }
      let(:current_year) { Date.today.year }

      it "returns tournament_id when only one tournament exists for the week" do
        tournament = create(:tournament, week_number: current_week, year: current_year)

        result = described_class.determine_current_tourn_id
        expect(result).to eq(tournament.tournament_id)
      end

      it "returns tournament_id with higher purse when multiple tournaments exist" do
        lower_purse = create(:tournament, week_number: current_week, year: current_year, purse: 8000000)
        higher_purse = create(:tournament, week_number: current_week, year: current_year, purse: 9500000)

        result = described_class.determine_current_tourn_id
        expect(result).to eq(higher_purse.tournament_id)
      end
    end

    describe ".determine_current_tourn_unique_id" do
      let(:current_week) { Date.today.strftime("%V").to_i }
      let(:current_year) { Date.today.year }

      it "returns unique_id for the current tournament" do
        tournament = create(:tournament, week_number: current_week, year: current_year, unique_id: "ABC123")

        result = described_class.determine_current_tourn_unique_id
        expect(result).to eq(tournament.unique_id)
      end
    end

    describe ".more_than_one_current_tourn?" do
      it "returns true when multiple tournaments exist" do
        tournaments = [
          instance_double("Tournament"),
          instance_double("Tournament")
        ]

        expect(described_class.more_than_one_current_tourn?(tournaments)).to be true
      end

      it "returns false when one or no tournaments exist" do
        single_tournament = [ instance_double("Tournament") ]
        no_tournaments = []

        expect(described_class.more_than_one_current_tourn?(single_tournament)).to be false
        expect(described_class.more_than_one_current_tourn?(no_tournaments)).to be false
      end
    end

    describe ".determine_more_valuable_tourn" do
      it "returns tournament_id of tournament with highest purse" do
        lower_purse = instance_double("Tournament", tournament_id: 1, purse: 8000000)
        higher_purse = instance_double("Tournament", tournament_id: 2, purse: 9500000)
        tournaments = [ lower_purse, higher_purse ]

        result = described_class.determine_more_valuable_tourn(tournaments)
        expect(result).to eq(higher_purse)
      end

      it "returns nil when no tournaments are provided" do
        result = described_class.determine_more_valuable_tourn([])
        expect(result).to be_nil
      end
    end

    describe ".determine_current_week" do
      it "returns current week number for given date" do
        date = Date.new(2024, 2, 1)  # Week 5 of 2024
        expect(described_class.determine_current_week(date)).to eq(5)
      end

      it "returns current week number for today when no date provided" do
        expected_week = Date.today.strftime("%V").to_i
        expect(described_class.determine_current_week).to eq(expected_week)
      end
    end
  end
end

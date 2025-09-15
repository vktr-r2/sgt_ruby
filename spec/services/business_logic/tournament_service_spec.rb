require 'rails_helper'

RSpec.describe BusinessLogic::TournamentService do
  let(:test_date) { Date.new(2024, 6, 15) } # June 15, 2024 (Week 24)
  subject(:service) { described_class.new(test_date) }

  describe '#initialize' do
    it 'accepts a date parameter' do
      service = described_class.new(test_date)
      expect(service.instance_variable_get(:@date)).to eq(test_date)
    end

    it 'defaults to today if no date provided' do
      service = described_class.new
      expect(service.instance_variable_get(:@date)).to eq(Date.today)
    end
  end

  describe '#current_tournament' do
    context 'with no tournaments for the current week' do
      it 'returns nil' do
        expect(service.current_tournament).to be_nil
      end
    end

    context 'with one tournament for the current week' do
      let!(:tournament) do
        create(:tournament, 
               week_number: test_date.strftime("%V").to_i, 
               year: test_date.year,
               name: 'Test Championship')
      end

      it 'returns the tournament' do
        expect(service.current_tournament).to eq(tournament)
      end
    end

    context 'with multiple tournaments for the current week' do
      let!(:regular_tournament) do
        create(:tournament,
               week_number: test_date.strftime("%V").to_i,
               year: test_date.year,
               name: 'Regular Tournament',
               purse: 5000000)
      end

      let!(:major_tournament) do
        create(:tournament,
               week_number: test_date.strftime("%V").to_i,
               year: test_date.year,
               name: 'High Purse Tournament',
               purse: 15000000)
      end

      it 'returns the tournament with the highest purse' do
        expect(service.current_tournament).to eq(major_tournament)
      end
    end

    context 'with tournaments in different weeks' do
      let!(:past_tournament) do
        create(:tournament,
               week_number: test_date.strftime("%V").to_i - 1,
               year: test_date.year,
               name: 'Past Tournament')
      end

      let!(:future_tournament) do
        create(:tournament,
               week_number: test_date.strftime("%V").to_i + 1,
               year: test_date.year,
               name: 'Future Tournament')
      end

      let!(:current_tournament) do
        create(:tournament,
               week_number: test_date.strftime("%V").to_i,
               year: test_date.year,
               name: 'Current Tournament')
      end

      it 'returns only the current week tournament' do
        expect(service.current_tournament).to eq(current_tournament)
      end
    end

    context 'with tournaments in different years' do
      let!(:wrong_year_tournament) do
        create(:tournament,
               week_number: test_date.strftime("%V").to_i,
               year: test_date.year - 1,
               name: 'Wrong Year Tournament')
      end

      let!(:current_year_tournament) do
        create(:tournament,
               week_number: test_date.strftime("%V").to_i,
               year: test_date.year,
               name: 'Current Year Tournament')
      end

      it 'returns only the current year tournament' do
        expect(service.current_tournament).to eq(current_year_tournament)
      end
    end

    context 'with no tournaments for current week but tournament in draft window' do
      let!(:draft_window_tournament) do
        # Tournament starts in 2 days (within draft window)
        start_date = test_date + 2.days
        create(:tournament,
               week_number: start_date.strftime("%V").to_i,
               year: test_date.year,
               start_date: start_date,
               end_date: start_date + 3.days,
               name: 'Draft Window Tournament')
      end

      it 'returns the tournament in draft window' do
        # Mock Time.zone.now to return the test_date
        allow(Time.zone).to receive(:now).and_return(test_date.beginning_of_day)
        expect(service.current_tournament).to eq(draft_window_tournament)
      end
    end

    context 'with tournaments in both current week and draft window' do
      let!(:current_week_tournament) do
        create(:tournament,
               week_number: test_date.strftime("%V").to_i,
               year: test_date.year,
               name: 'Current Week Tournament')
      end

      let!(:draft_window_tournament) do
        start_date = test_date + 2.days
        create(:tournament,
               week_number: start_date.strftime("%V").to_i,
               year: test_date.year,
               start_date: start_date,
               end_date: start_date + 3.days,
               name: 'Draft Window Tournament')
      end

      it 'prioritizes current week tournament over draft window tournament' do
        expect(service.current_tournament).to eq(current_week_tournament)
      end
    end
  end

  describe '#current_tournament_id' do
    let!(:tournament) do
      create(:tournament,
             week_number: test_date.strftime("%V").to_i,
             year: test_date.year,
             tournament_id: 'test_tournament_123')
    end

    it 'returns the tournament_id of the current tournament' do
      expect(service.current_tournament_id).to eq('test_tournament_123')
    end
  end

  describe '#current_tournament_unique_id' do
    let!(:tournament) do
      create(:tournament,
             week_number: test_date.strftime("%V").to_i,
             year: test_date.year,
             unique_id: 'unique_test_123')
    end

    it 'returns the unique_id of the current tournament' do
      expect(service.current_tournament_unique_id).to eq('unique_test_123')
    end
  end

  describe '#is_major?' do
    it 'identifies major tournaments correctly (case insensitive)' do
      expect(service.is_major?('Masters Tournament')).to be true
      expect(service.is_major?('MASTERS TOURNAMENT')).to be true
      expect(service.is_major?('masters tournament')).to be true
      
      expect(service.is_major?('PGA Championship')).to be true
      expect(service.is_major?('pga championship')).to be true
      
      expect(service.is_major?('The Open Championship')).to be true
      expect(service.is_major?('the open championship')).to be true
      
      expect(service.is_major?('U.S. Open')).to be true
      expect(service.is_major?('u.s. open')).to be true
    end

    it 'returns false for non-major tournaments' do
      expect(service.is_major?('Arnold Palmer Invitational')).to be false
      expect(service.is_major?('The Players Championship')).to be false
      expect(service.is_major?('Genesis Open')).to be false
      expect(service.is_major?('Random Tournament')).to be false
    end

    it 'handles empty and nil inputs' do
      expect(service.is_major?('')).to be false
      expect(service.is_major?(nil)).to be false
    end
  end

  describe 'private methods' do
    describe '#current_week' do
      it 'returns the correct ISO week number' do
        # June 15, 2024 is week 24
        expected_week = test_date.strftime("%V").to_i
        expect(service.send(:current_week)).to eq(expected_week)
      end

      it 'handles different dates correctly' do
        jan_service = described_class.new(Date.new(2024, 1, 15))
        expect(jan_service.send(:current_week)).to eq(3) # January 15, 2024 is week 3

        dec_service = described_class.new(Date.new(2024, 12, 15))
        expect(dec_service.send(:current_week)).to eq(50) # December 15, 2024 is week 50
      end
    end

    describe '#more_than_one_current_tourn?' do
      it 'returns true when multiple tournaments exist' do
        tournaments = create_list(:tournament, 3)
        expect(service.send(:more_than_one_current_tourn?, tournaments)).to be true
      end

      it 'returns false when one tournament exists' do
        tournaments = [create(:tournament)]
        expect(service.send(:more_than_one_current_tourn?, tournaments)).to be false
      end

      it 'returns false when no tournaments exist' do
        tournaments = []
        expect(service.send(:more_than_one_current_tourn?, tournaments)).to be false
      end
    end

    describe '#determine_more_valuable_tourn' do
      let(:low_purse_tournament) { create(:tournament, purse: 5000000) }
      let(:high_purse_tournament) { create(:tournament, purse: 15000000) }
      let(:tournaments) { [low_purse_tournament, high_purse_tournament] }

      it 'returns the tournament with the highest purse' do
        result = service.send(:determine_more_valuable_tourn, tournaments)
        expect(result).to eq(high_purse_tournament)
      end

      it 'handles tournaments with nil purse' do
        nil_purse_tournament = create(:tournament, purse: nil)
        tournaments_with_nil = [nil_purse_tournament, high_purse_tournament]
        
        result = service.send(:determine_more_valuable_tourn, tournaments_with_nil)
        expect(result).to eq(high_purse_tournament)
      end
    end
  end

  describe 'edge cases' do
    it 'handles year boundary correctly' do
      # Test around New Year
      new_years_service = described_class.new(Date.new(2024, 1, 1))
      expect(new_years_service.send(:current_week)).to eq(1)
      
      # Create tournament for week 1 of 2024
      tournament = create(:tournament, week_number: 1, year: 2024)
      expect(new_years_service.current_tournament).to eq(tournament)
    end

    it 'handles leap year correctly' do
      # Test during leap year
      leap_year_service = described_class.new(Date.new(2024, 2, 29))
      expect(leap_year_service.send(:current_week)).to eq(9) # February 29, 2024 is week 9
    end
  end
end
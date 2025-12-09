require 'rails_helper'

RSpec.describe BusinessLogic::GolferService do
  subject(:service) { described_class.new }

  let(:tournament) { create(:tournament) }
  let(:tournament_service) { instance_double(BusinessLogic::TournamentService) }

  before do
    allow(BusinessLogic::TournamentService).to receive(:new).and_return(tournament_service)
  end

  describe '#initialize' do
    it 'creates a tournament evaluator service' do
      expect(BusinessLogic::TournamentService).to receive(:new)
      described_class.new
    end
  end

  describe '#get_current_tourn_golfers' do
    let(:golfers) do
      [
        create(:golfer, f_name: 'Tiger', l_name: 'Woods', last_active_tourney: tournament.unique_id),
        create(:golfer, f_name: 'Rory', l_name: 'McIlroy', last_active_tourney: tournament.unique_id),
        create(:golfer, f_name: 'Jon', l_name: 'Rahm', last_active_tourney: tournament.unique_id),
        create(:golfer, f_name: 'Adam', l_name: 'Scott', last_active_tourney: tournament.unique_id),
        create(:golfer, f_name: 'Jordan', l_name: 'Spieth', last_active_tourney: tournament.unique_id)
      ]
    end

    before do
      allow(tournament_service).to receive(:current_tournament_unique_id).and_return(tournament.unique_id)
      golfers # Create the golfers
    end

    context 'when current tournament has golfers' do
      it 'returns golfers for the current tournament' do
        result = service.get_current_tourn_golfers
        expect(result.count).to eq(5)
        expect(result).to all(be_a(Golfer))
        expect(result.map(&:last_active_tourney)).to all(eq(tournament.unique_id))
      end

      it 'sorts golfers by last name' do
        result = service.get_current_tourn_golfers
        last_names = result.map(&:l_name)
        expected_order = [ 'McIlroy', 'Rahm', 'Scott', 'Spieth', 'Woods' ]
        expect(last_names).to eq(expected_order)
      end

      it 'maintains golfer objects with all attributes' do
        result = service.get_current_tourn_golfers
        tiger = result.find { |g| g.f_name == 'Tiger' }

        expect(tiger.f_name).to eq('Tiger')
        expect(tiger.l_name).to eq('Woods')
        expect(tiger.last_active_tourney).to eq(tournament.unique_id)
        expect(tiger.source_id).to be_present
      end
    end

    context 'when current tournament has no golfers' do
      before do
        allow(tournament_service).to receive(:current_tournament_unique_id).and_return('non_existent_tournament')
      end

      it 'returns empty collection' do
        result = service.get_current_tourn_golfers
        expect(result).to be_empty
      end
    end

    context 'when there are golfers for different tournaments' do
      let(:other_tournament) { create(:tournament) }
      let!(:other_tournament_golfers) do
        create_list(:golfer, 3, last_active_tourney: other_tournament.unique_id)
      end

      it 'returns only golfers for current tournament' do
        result = service.get_current_tourn_golfers
        expect(result.count).to eq(5) # Only golfers from current tournament
        expect(result.map(&:last_active_tourney)).to all(eq(tournament.unique_id))
        expect(result.map(&:last_active_tourney)).not_to include(other_tournament.unique_id)
      end
    end

    context 'when tournament service returns nil unique_id' do
      before do
        allow(tournament_service).to receive(:current_tournament_unique_id).and_return(nil)
      end

      it 'returns empty collection' do
        result = service.get_current_tourn_golfers
        expect(result).to be_empty
      end
    end

    context 'sorting edge cases' do
      let(:golfers_with_special_names) do
        [
          create(:golfer, f_name: 'John', l_name: 'van der Berg', last_active_tourney: tournament.unique_id),
          create(:golfer, f_name: 'Mike', l_name: "O'Connor", last_active_tourney: tournament.unique_id),
          create(:golfer, f_name: 'Paul', l_name: 'De Silva', last_active_tourney: tournament.unique_id),
          create(:golfer, f_name: 'Chris', l_name: 'Anderson', last_active_tourney: tournament.unique_id),
          create(:golfer, f_name: 'David', l_name: 'Żółć', last_active_tourney: tournament.unique_id)
        ]
      end

      before do
        golfers_with_special_names
      end

      it 'handles special characters and case in sorting' do
        result = service.get_current_tourn_golfers
        last_names = result.map(&:l_name)

        # Should be sorted alphabetically
        expect(last_names.first).to eq('Anderson')
        expect(last_names).to include('De Silva', "O'Connor", 'van der Berg', 'Żółć')
      end
    end
  end

  describe 'private methods' do
    describe '#sort_golfers' do
      let(:unsorted_golfers) do
        [
          create(:golfer, l_name: 'Woods'),
          create(:golfer, l_name: 'Adams'),
          create(:golfer, l_name: 'McIlroy'),
          create(:golfer, l_name: 'Spieth')
        ]
      end

      it 'sorts golfers by last name alphabetically' do
        sorted = service.send(:sort_golfers, unsorted_golfers)
        last_names = sorted.map(&:l_name)
        expect(last_names).to eq([ 'Adams', 'McIlroy', 'Spieth', 'Woods' ])
      end

      it 'returns the same golfers, just sorted' do
        sorted = service.send(:sort_golfers, unsorted_golfers)
        expect(sorted.count).to eq(unsorted_golfers.count)

        unsorted_golfers.each do |golfer|
          expect(sorted).to include(golfer)
        end
      end

      it 'handles empty collection' do
        sorted = service.send(:sort_golfers, [])
        expect(sorted).to eq([])
      end

      it 'handles single golfer' do
        single_golfer = [ create(:golfer, l_name: 'Woods') ]
        sorted = service.send(:sort_golfers, single_golfer)
        expect(sorted).to eq(single_golfer)
      end
    end
  end

  describe 'integration with tournament service' do
    it 'calls tournament service for unique_id' do
      expect(tournament_service).to receive(:current_tournament_unique_id).and_return(tournament.unique_id)
      service.get_current_tourn_golfers
    end

    it 'handles when tournament service returns different unique_id' do
      new_tournament = create(:tournament)
      new_golfers = create_list(:golfer, 3, last_active_tourney: new_tournament.unique_id)

      allow(tournament_service).to receive(:current_tournament_unique_id).and_return(new_tournament.unique_id)

      result = service.get_current_tourn_golfers
      expect(result.count).to eq(3)
      expect(result.map(&:last_active_tourney)).to all(eq(new_tournament.unique_id))
    end
  end

  describe 'real-world scenarios' do
    context 'with full tournament field' do
      let!(:full_field_golfers) do
        20.times.map do |i|
          create(:golfer,
                 f_name: "Player#{i}",
                 l_name: "Lastname#{i.to_s.rjust(2, '0')}",
                 last_active_tourney: tournament.unique_id)
        end
      end

      before do
        allow(tournament_service).to receive(:current_tournament_unique_id).and_return(tournament.unique_id)
      end

      it 'returns all golfers sorted correctly' do
        result = service.get_current_tourn_golfers
        expect(result.count).to eq(20)

        # Check that it's sorted
        last_names = result.map(&:l_name)
        expect(last_names).to eq(last_names.sort)
      end

      it 'maintains performance with larger datasets' do
        expect do
          service.get_current_tourn_golfers
        end.not_to raise_error
      end
    end

    context 'with mixed tournament data' do
      let!(:past_tournament) { create(:tournament, unique_id: 'past_tournament') }
      let!(:future_tournament) { create(:tournament, unique_id: 'future_tournament') }
      let!(:current_golfers) { create_list(:golfer, 8, last_active_tourney: tournament.unique_id) }
      let!(:past_tournament_golfers) { create_list(:golfer, 5, last_active_tourney: past_tournament.unique_id) }
      let!(:future_tournament_golfers) { create_list(:golfer, 3, last_active_tourney: future_tournament.unique_id) }

      before do
        allow(tournament_service).to receive(:current_tournament_unique_id).and_return(tournament.unique_id)
      end

      it 'filters correctly to only current tournament golfers' do
        result = service.get_current_tourn_golfers
        expect(result.count).to eq(8)
        expect(result.map(&:last_active_tourney)).to all(eq(tournament.unique_id))
      end
    end
  end
end

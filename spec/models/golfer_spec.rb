require 'rails_helper'

RSpec.describe Golfer, type: :model do
  let(:tournament) { create(:tournament) }

  describe 'associations' do
    it { should belong_to(:tournament).with_foreign_key('last_active_tourney').with_primary_key('unique_id') }

    it 'belongs to a tournament via unique_id' do
      golfer = create(:golfer, last_active_tourney: tournament.unique_id)
      expect(golfer.tournament).to eq(tournament)
    end

    it 'is invalid without a valid tournament' do
      golfer = build(:golfer, last_active_tourney: 'non_existent_tournament')
      expect(golfer).not_to be_valid
      expect(golfer.errors[:tournament]).to include("must exist")
    end

    it 'can be associated with a tournament by unique_id' do
      golfer = create(:golfer, last_active_tourney: tournament.unique_id)
      expect(golfer.last_active_tourney).to eq(tournament.unique_id)
      expect(golfer.tournament.unique_id).to eq(tournament.unique_id)
    end
  end

  describe 'attributes' do
    it 'has first and last name attributes' do
      golfer = create(:golfer,
                      f_name: 'Tiger',
                      l_name: 'Woods',
                      last_active_tourney: tournament.unique_id)

      expect(golfer.f_name).to eq('Tiger')
      expect(golfer.l_name).to eq('Woods')
    end

    it 'has source_id attribute for external API reference' do
      golfer = create(:golfer,
                      source_id: 'api_golfer_123',
                      last_active_tourney: tournament.unique_id)

      expect(golfer.source_id).to eq('api_golfer_123')
    end

    it 'can store tournament reference correctly' do
      golfer = create(:golfer, last_active_tourney: tournament.unique_id)
      expect(golfer.last_active_tourney).to eq(tournament.unique_id)
    end
  end

  describe 'golfer creation scenarios' do
    it 'creates golfers for a tournament' do
      golfer1 = create(:golfer, f_name: 'Tiger', l_name: 'Woods', last_active_tourney: tournament.unique_id)
      golfer2 = create(:golfer, f_name: 'Rory', l_name: 'McIlroy', last_active_tourney: tournament.unique_id)

      tournament_golfers = Golfer.where(last_active_tourney: tournament.unique_id)
      expect(tournament_golfers).to include(golfer1, golfer2)
      expect(tournament_golfers.count).to eq(2)
    end

    it 'can create multiple tournaments with different golfers' do
      tournament2 = create(:tournament)

      golfer1 = create(:golfer, f_name: 'Player1', last_active_tourney: tournament.unique_id)
      golfer2 = create(:golfer, f_name: 'Player2', last_active_tourney: tournament2.unique_id)

      expect(Golfer.where(last_active_tourney: tournament.unique_id)).to include(golfer1)
      expect(Golfer.where(last_active_tourney: tournament.unique_id)).not_to include(golfer2)
      expect(Golfer.where(last_active_tourney: tournament2.unique_id)).to include(golfer2)
      expect(Golfer.where(last_active_tourney: tournament2.unique_id)).not_to include(golfer1)
    end

    it 'can have the same golfer in different tournaments' do
      tournament2 = create(:tournament)

      golfer1 = create(:golfer,
                       f_name: 'Tiger',
                       l_name: 'Woods',
                       source_id: 'tiger_1',
                       last_active_tourney: tournament.unique_id)

      golfer2 = create(:golfer,
                       f_name: 'Tiger',
                       l_name: 'Woods',
                       source_id: 'tiger_2',
                       last_active_tourney: tournament2.unique_id)

      expect(golfer1.f_name).to eq(golfer2.f_name)
      expect(golfer1.last_active_tourney).not_to eq(golfer2.last_active_tourney)
      expect(golfer1.tournament).not_to eq(golfer2.tournament)
    end
  end

  describe 'full name helpers' do
    it 'can generate full name from first and last names' do
      golfer = create(:golfer, f_name: 'Tiger', l_name: 'Woods', last_active_tourney: tournament.unique_id)
      # Since we don't have a full_name method in the model, we can test the data is there for the view layer
      expect("#{golfer.f_name} #{golfer.l_name}").to eq('Tiger Woods')
    end
  end

  describe 'factory' do
    it 'creates a valid golfer with factory' do
      golfer = create(:golfer, last_active_tourney: tournament.unique_id)
      expect(golfer).to be_persisted
      expect(golfer).to be_valid
      expect(golfer.f_name).to be_present
      expect(golfer.l_name).to be_present
      expect(golfer.source_id).to be_present
    end

    it 'creates unique golfers with factory sequence' do
      golfer1 = create(:golfer, last_active_tourney: tournament.unique_id)
      golfer2 = create(:golfer, last_active_tourney: tournament.unique_id)

      expect(golfer1.f_name).not_to eq(golfer2.f_name)
      expect(golfer1.source_id).not_to eq(golfer2.source_id)
    end
  end
end

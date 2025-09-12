require 'rails_helper'

RSpec.describe BusinessLogic::GolferLimitValidationService, type: :model do
  let(:user) { create(:user) }
  let(:current_year) { Date.current.year }
  
  let!(:tournament1) do
    create(:tournament, 
           start_date: Date.new(current_year, 1, 15),
           unique_id: "tournament-1-#{current_year}")
  end
  
  let!(:tournament2) do
    create(:tournament,
           start_date: Date.new(current_year, 2, 15),
           unique_id: "tournament-2-#{current_year}")
  end
  
  let!(:tournament3) do
    create(:tournament,
           start_date: Date.new(current_year, 3, 15),
           unique_id: "tournament-3-#{current_year}")
  end
  
  let!(:tournament_different_year) do
    create(:tournament,
           start_date: Date.new(current_year - 1, 1, 15),
           unique_id: "tournament-old-#{current_year - 1}")
  end
  
  let!(:scottie) { create(:golfer, f_name: "Scottie", l_name: "Scheffler") }
  let!(:rory) { create(:golfer, f_name: "Rory", l_name: "McIlroy") }
  let!(:tiger) { create(:golfer, f_name: "Tiger", l_name: "Woods") }

  describe '#validate' do
    context 'when user has not exceeded the limit' do
      before do
        # Create 2 picks for Scottie in current year
        create(:match_pick, user: user, tournament: tournament1, golfer: scottie, drafted: true)
        create(:match_pick, user: user, tournament: tournament2, golfer: scottie, drafted: true)
      end

      it 'allows the selection' do
        service = described_class.new(user.id, [scottie.id])
        result = service.validate
        
        expect(result[:valid]).to be true
        expect(result[:violations]).to be_empty
      end
    end

    context 'when user has exactly reached the limit' do
      before do
        # Create 3 picks for Scottie in current year (at the limit)
        create(:match_pick, user: user, tournament: tournament1, golfer: scottie, drafted: true)
        create(:match_pick, user: user, tournament: tournament2, golfer: scottie, drafted: true)
        create(:match_pick, user: user, tournament: tournament3, golfer: scottie, drafted: true)
      end

      it 'blocks further selections of that golfer' do
        service = described_class.new(user.id, [scottie.id])
        result = service.validate
        
        expect(result[:valid]).to be false
        expect(result[:violations].size).to eq(1)
        
        violation = result[:violations].first
        expect(violation[:golfer_id]).to eq(scottie.id)
        expect(violation[:golfer_name]).to eq("Scottie Scheffler")
        expect(violation[:current_count]).to eq(3)
        expect(violation[:message]).to include("Scottie Scheffler rule violation")
        expect(violation[:message]).to include("3 times this year")
      end
    end

    context 'when user selects multiple golfers with violations' do
      before do
        # Create 3 picks for both Scottie and Rory
        create(:match_pick, user: user, tournament: tournament1, golfer: scottie, drafted: true)
        create(:match_pick, user: user, tournament: tournament2, golfer: scottie, drafted: true)
        create(:match_pick, user: user, tournament: tournament3, golfer: scottie, drafted: true)
        
        create(:match_pick, user: user, tournament: tournament1, golfer: rory, drafted: true)
        create(:match_pick, user: user, tournament: tournament2, golfer: rory, drafted: true)
        create(:match_pick, user: user, tournament: tournament3, golfer: rory, drafted: true)
      end

      it 'returns the first violation only' do
        service = described_class.new(user.id, [scottie.id, rory.id, tiger.id])
        result = service.validate
        
        expect(result[:valid]).to be false
        expect(result[:violations].size).to eq(2)
        
        # Should include violations for both Scottie and Rory
        violation_names = result[:violations].map { |v| v[:golfer_name] }
        expect(violation_names).to contain_exactly("Scottie Scheffler", "Rory McIlroy")
      end
    end

    context 'when picks are from different years' do
      before do
        # Create 3 picks in previous year (should not count)
        3.times do |i|
          create(:match_pick, user: user, tournament: tournament_different_year, golfer: scottie, drafted: true)
        end
        
        # Create 2 picks in current year
        create(:match_pick, user: user, tournament: tournament1, golfer: scottie, drafted: true)
        create(:match_pick, user: user, tournament: tournament2, golfer: scottie, drafted: true)
      end

      it 'only counts current year picks' do
        service = described_class.new(user.id, [scottie.id])
        result = service.validate
        
        expect(result[:valid]).to be true
        expect(result[:violations]).to be_empty
      end
    end

    context 'when picks have drafted: false' do
      before do
        # Create 3 picks with drafted: false (should not count)
        create(:match_pick, user: user, tournament: tournament1, golfer: scottie, drafted: false)
        create(:match_pick, user: user, tournament: tournament2, golfer: scottie, drafted: false)
        create(:match_pick, user: user, tournament: tournament3, golfer: scottie, drafted: false)
      end

      it 'only counts drafted picks' do
        service = described_class.new(user.id, [scottie.id])
        result = service.validate
        
        expect(result[:valid]).to be true
        expect(result[:violations]).to be_empty
      end
    end

    context 'when picks belong to different users' do
      let(:other_user) { create(:user) }
      
      before do
        # Create 3 picks for other user
        create(:match_pick, user: other_user, tournament: tournament1, golfer: scottie, drafted: true)
        create(:match_pick, user: other_user, tournament: tournament2, golfer: scottie, drafted: true)
        create(:match_pick, user: other_user, tournament: tournament3, golfer: scottie, drafted: true)
      end

      it 'only counts picks for the specified user' do
        service = described_class.new(user.id, [scottie.id])
        result = service.validate
        
        expect(result[:valid]).to be true
        expect(result[:violations]).to be_empty
      end
    end

    context 'when golfer does not exist' do
      it 'handles missing golfers gracefully' do
        non_existent_id = 99999
        service = described_class.new(user.id, [non_existent_id])
        result = service.validate
        
        expect(result[:valid]).to be true
        expect(result[:violations]).to be_empty
      end
    end

    context 'when no tournaments exist in current year' do
      before do
        Tournament.destroy_all
      end

      it 'allows all selections' do
        service = described_class.new(user.id, [scottie.id])
        result = service.validate
        
        expect(result[:valid]).to be true
        expect(result[:violations]).to be_empty
      end
    end

    context 'when SCOTTIE_SCHEFFLER_LIMIT constant is used' do
      it 'uses the configured limit' do
        # Create exactly SCOTTIE_SCHEFFLER_LIMIT picks
        MatchPick::GOLFER_SELECTION_LIMIT.times do |i|
          tournament = create(:tournament, 
                             start_date: Date.new(current_year, i + 1, 15),
                             unique_id: "limit-test-#{i}-#{current_year}")
          create(:match_pick, user: user, tournament: tournament, golfer: scottie, drafted: true)
        end

        service = described_class.new(user.id, [scottie.id])
        result = service.validate
        
        expect(result[:valid]).to be false
        violation = result[:violations].first
        expect(violation[:current_count]).to eq(MatchPick::GOLFER_SELECTION_LIMIT)
      end
    end
  end
end
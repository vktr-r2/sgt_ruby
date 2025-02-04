require 'rails_helper'

RSpec.describe Mappers::GolferMapper, type: :model do
  describe '#map_to_attributes' do
    let(:tournament_unique_id) { SecureRandom.base64(10) }

    context 'with complete golfer data' do
      let(:golfer) { build(:golfer) }
      let(:golfer_data) do
        {
          "playerId" => golfer.source_id,
          "firstName" => golfer.f_name,
          "lastName" => golfer.l_name
        }
      end

      subject(:mapper) { described_class.new(golfer_data, tournament_unique_id) }

      it 'correctly maps golfer attributes' do
        mapped_attributes = mapper.map_to_attributes

        expect(mapped_attributes).to eq({
          "source_id" => golfer.source_id,
          "f_name" => golfer.f_name,
          "l_name" => golfer.l_name,
          "last_active_tourney" => tournament_unique_id
        })
      end
    end

    context 'with custom golfer data' do
      let(:golfer) { build(:golfer, f_name: "John", l_name: "Doe", source_id: "custom_id") }
      let(:golfer_data) do
        {
          "playerId" => golfer.source_id,
          "firstName" => golfer.f_name,
          "lastName" => golfer.l_name
        }
      end

      subject(:mapper) { described_class.new(golfer_data, tournament_unique_id) }

      it 'maps custom golfer attributes correctly' do
        mapped_attributes = mapper.map_to_attributes

        expect(mapped_attributes).to eq({
          "source_id" => "custom_id",
          "f_name" => "John",
          "l_name" => "Doe",
          "last_active_tourney" => tournament_unique_id
        })
      end
    end
  end
end

require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe ApplicationHelper::DateOperations do
    describe '.date_hash_to_time_obj' do
      it 'converts MongoDB date hash to Time object' do
        date_hash = { "$date" => { "$numberLong" => "1706832000000" } }  # Feb 1, 2024
        result = described_class.date_hash_to_time_obj(date_hash)

        expect(result).to be_a(Time)
        expect(result.to_i).to eq(1706832000)
      end
    end

    describe '.extract_year_from_date_hash' do
      it 'extracts year from MongoDB date hash' do
        date_hash = { "$date" => { "$numberLong" => "1706832000000" } }  # Feb 1, 2024
        result = described_class.extract_year_from_date_hash(date_hash)

        expect(result).to eq(2024)
      end
    end
  end
end

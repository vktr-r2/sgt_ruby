require 'rails_helper'

RSpec.describe Importers::ScheduleImporter, type: :model do
  describe '#process' do
    let(:schedule_data) do
      {
        "schedule" => [
          {
            "tournamentId" => "test_tournament_1",
            "year" => 2024,
            "name" => "Test Tournament 1"
          },
          {
            "tournamentId" => "test_tournament_2",
            "year" => 2024,
            "name" => "Test Tournament 2"
          }
        ]
      }
    end

    let(:mapper_double) { instance_double(Mappers::ScheduleMapper) }
    let(:importer) { described_class.new(schedule_data) }

    before do
      allow(Mappers::ScheduleMapper).to receive(:new).and_return(mapper_double)
    end

    context 'when processing schedule data' do
      before do
        # Stub the mapper to return predefined attributes
        allow(mapper_double).to receive(:map_to_attributes).with(no_args).and_return(
          {
            tournament_id: "test_tournament_1",
            year: 2024,
            name: "Test Tournament 1"
          }
        )
      end

      it 'calls ScheduleMapper for each tournament' do
        expect(Mappers::ScheduleMapper).to receive(:new).twice
        expect(mapper_double).to receive(:map_to_attributes).twice

        importer.process
      end
    end

    context 'when saving tournaments' do
      let!(:existing_tournament) { create(:tournament, tournament_id: "test_tournament_1", year: 2024) }

      before do
        allow(mapper_double).to receive(:map_to_attributes).and_return(
          {
            tournament_id: "test_tournament_1",
            year: 2024,
            name: "Updated Test Tournament 1"
          }
        )
      end

      it 'finds and updates existing tournament' do
        expect {
          importer.process
        }.to change { existing_tournament.reload.name }.to("Updated Test Tournament 1")
      end
    end

    context 'when tournament save fails' do
      before do
        # Create a tournament that will fail validation
        allow(mapper_double).to receive(:map_to_attributes).and_return(
          {
            tournament_id: "test_tournament_invalid",
            year: 2024,
            name: nil  # Assuming name is required and can't be nil
          }
        )

        # Stub Rails logger to prevent actual logging
        allow(Rails.logger).to receive(:error)
        allow(Rails.logger).to receive(:info)
      end

      it 'logs an error when validation fails' do
        expect(Rails.logger).to receive(:error).with(a_string_including("Validation failed"))

        importer.process
      end
    end

    context 'when an unexpected error occurs' do
      before do
        allow(mapper_double).to receive(:map_to_attributes).and_return(
          {
            tournament_id: "test_tournament_error",
            year: 2024,
            name: "Test Tournament"
          }
        )

        # Simulate an unexpected error during save
        allow_any_instance_of(Tournament).to receive(:save).and_raise(StandardError.new("Unexpected error"))

        # Stub Rails logger to prevent actual logging
        allow(Rails.logger).to receive(:error)
      end

      it 'logs an unexpected error' do
        expect(Rails.logger).to receive(:error).with(a_string_including("An unexpected error occurred"))

        importer.process
      end
    end
  end
end

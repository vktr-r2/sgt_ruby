require 'rails_helper'

RSpec.describe Importers::ScheduleImporter, type: :model do
  describe '#process' do
    let(:schedule_service_double) { instance_double(BusinessLogic::ScheduleService) }
    let(:mapper_double) { instance_double(Mappers::ScheduleMapper) }

    before do
      allow(BusinessLogic::ScheduleService).to receive(:new).and_return(schedule_service_double)
      allow(schedule_service_double).to receive(:season_start_date).and_return(Time.zone.parse('2024-01-01'))
      allow(schedule_service_double).to receive(:season_end_date).and_return(Time.zone.parse('2024-12-31'))

      allow(Mappers::ScheduleMapper).to receive(:new).and_return(mapper_double)
      allow(mapper_double).to receive(:map_to_attributes).and_return({
        tournament_id: "valid_tournament",
        year: 2024,
        name: "Valid Tournament"
      })

      # Mock the date conversion method to return dates within our season range
      allow(ApplicationHelper::DateOperations).to receive(:date_hash_to_time_obj) do |date_hash|
        if date_hash["year"] && date_hash["month"] && date_hash["day"]
          Time.zone.local(date_hash["year"], date_hash["month"], date_hash["day"])
        else
          Time.zone.parse('2024-06-15') # Default date within season
        end
      end
    end

    context 'when processing stroke play tournaments within season' do
      let(:schedule_data) do
        {
          "schedule" => [
            {
              "tournamentId" => "stroke_tournament_1",
              "year" => 2024,
              "name" => "Stroke Play Tournament 1",
              "format" => "stroke",
              "date" => {
                "start" => {
                  "year" => 2024,
                  "month" => 6,
                  "day" => 20
                }
              }
            },
            {
              "tournamentId" => "stroke_tournament_2",
              "year" => 2024,
              "name" => "Stroke Play Tournament 2",
              "format" => "stroke",
              "date" => {
                "start" => {
                  "year" => 2024,
                  "month" => 7,
                  "day" => 15
                }
              }
            }
          ]
        }
      end

      let(:importer) { described_class.new(schedule_data) }

      it 'processes all valid stroke play tournaments' do
        expect(Mappers::ScheduleMapper).to receive(:new).twice
        expect(mapper_double).to receive(:map_to_attributes).twice

        importer.process
      end
    end

    context 'when filtering out non-stroke tournaments' do
      let(:schedule_data) do
        {
          "schedule" => [
            {
              "tournamentId" => "stroke_tournament",
              "year" => 2024,
              "name" => "Stroke Play Tournament",
              "format" => "stroke",
              "date" => {
                "start" => {
                  "year" => 2024,
                  "month" => 6,
                  "day" => 20
                }
              }
            },
            {
              "tournamentId" => "match_tournament",
              "year" => 2024,
              "name" => "Match Play Tournament",
              "format" => "match",
              "date" => {
                "start" => {
                  "year" => 2024,
                  "month" => 7,
                  "day" => 15
                }
              }
            }
          ]
        }
      end

      let(:importer) { described_class.new(schedule_data) }

      it 'only processes stroke play tournaments' do
        expect(Mappers::ScheduleMapper).to receive(:new).once
        expect(mapper_double).to receive(:map_to_attributes).once

        importer.process
      end
    end

    context 'when filtering out tournaments outside season dates' do
      let(:schedule_data) do
        {
          "schedule" => [
            {
              "tournamentId" => "in_season_tournament",
              "year" => 2024,
              "name" => "In Season Tournament",
              "format" => "stroke",
              "date" => {
                "start" => {
                  "year" => 2024,
                  "month" => 6,
                  "day" => 20
                }
              }
            },
            {
              "tournamentId" => "out_of_season_tournament",
              "year" => 2023,
              "name" => "Out of Season Tournament",
              "format" => "stroke",
              "date" => {
                "start" => {
                  "year" => 2023,
                  "month" => 12,
                  "day" => 15
                }
              }
            }
          ]
        }
      end

      let(:importer) { described_class.new(schedule_data) }

      it 'only processes tournaments within season date range' do
        expect(Mappers::ScheduleMapper).to receive(:new).once
        expect(mapper_double).to receive(:map_to_attributes).once

        importer.process
      end
    end

    context 'when saving tournaments' do
      let(:schedule_data) do
        {
          "schedule" => [
            {
              "tournamentId" => "test_tournament_1",
              "year" => 2024,
              "name" => "Test Tournament 1",
              "format" => "stroke",
              "date" => {
                "start" => {
                  "year" => 2024,
                  "month" => 6,
                  "day" => 20
                }
              }
            }
          ]
        }
      end

      let!(:existing_tournament) { create(:tournament, tournament_id: "test_tournament_1", year: 2024) }
      let(:importer) { described_class.new(schedule_data) }

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
      let(:schedule_data) do
        {
          "schedule" => [
            {
              "tournamentId" => "test_tournament_invalid",
              "year" => 2024,
              "name" => "Invalid Tournament",
              "format" => "stroke",
              "date" => {
                "start" => {
                  "year" => 2024,
                  "month" => 6,
                  "day" => 20
                }
              }
            }
          ]
        }
      end

      let(:importer) { described_class.new(schedule_data) }

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
      let(:schedule_data) do
        {
          "schedule" => [
            {
              "tournamentId" => "test_tournament_error",
              "year" => 2024,
              "name" => "Error Tournament",
              "format" => "stroke",
              "date" => {
                "start" => {
                  "year" => 2024,
                  "month" => 6,
                  "day" => 20
                }
              }
            }
          ]
        }
      end

      let(:importer) { described_class.new(schedule_data) }

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

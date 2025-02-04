require "rails_helper"

RSpec.describe Importers::TournamentImporter, type: :model do
  let(:tourn_data) do
    {
      "_id" => { "$oid" => "12345" },
      "players" => [
        { "source_id" => "g1", "name" => "Golfer One" },
        { "source_id" => "g2", "name" => "Golfer Two" }
      ]
    }
  end

  let(:tournament_mapper) { instance_double(Mappers::TournamentMapper, map_to_attributes: tournament_attributes) }
  let(:golfer_mapper_1) { instance_double(Mappers::GolferMapper, map_to_attributes: golfer_attributes_1) }
  let(:golfer_mapper_2) { instance_double(Mappers::GolferMapper, map_to_attributes: golfer_attributes_2) }

  let(:tournament_attributes) { { "tournament_id" => "t1", "year" => 2025, "name" => "Test Tournament" } }
  let(:golfer_attributes_1) { { "source_id" => "g1", "name" => "Golfer One" } }
  let(:golfer_attributes_2) { { "source_id" => "g2", "name" => "Golfer Two" } }

  let(:tournament) {
 instance_double(Tournament, assign_attributes: nil, save: true, name: "Test Tournament",
                             errors: double(full_messages: [])) }
  let(:golfer_1) {
 instance_double(Golfer, assign_attributes: nil, save: true, source_id: "g1", errors: double(full_messages: [])) }
  let(:golfer_2) {
 instance_double(Golfer, assign_attributes: nil, save: true, source_id: "g2", errors: double(full_messages: [])) }

  before do
    allow(Mappers::TournamentMapper).to receive(:new).with(tourn_data).and_return(tournament_mapper)
    allow(Mappers::GolferMapper).to receive(:new).with(tourn_data["players"].first, "12345").and_return(golfer_mapper_1)
    allow(Mappers::GolferMapper).to receive(:new).with(tourn_data["players"].last, "12345").and_return(golfer_mapper_2)
    allow(Tournament).to receive(:find_by).and_return(tournament)
    allow(Golfer).to receive(:find_or_initialize_by).with(source_id: "g1").and_return(golfer_1)
    allow(Golfer).to receive(:find_or_initialize_by).with(source_id: "g2").and_return(golfer_2)
  end

  subject { described_class.new(tourn_data) }

  describe "#process" do
    it "imports tournament and golfers successfully" do
      expect { subject.process }.not_to raise_error
      expect(Tournament).to have_received(:find_by).with(tournament_id: "t1", year: 2025)
      expect(tournament).to have_received(:assign_attributes).with(tournament_attributes)
      expect(tournament).to have_received(:save)
      expect(Golfer).to have_received(:find_or_initialize_by).with(source_id: "g1")
      expect(golfer_1).to have_received(:assign_attributes).with(golfer_attributes_1)
      expect(golfer_1).to have_received(:save)
      expect(Golfer).to have_received(:find_or_initialize_by).with(source_id: "g2")
      expect(golfer_2).to have_received(:assign_attributes).with(golfer_attributes_2)
      expect(golfer_2).to have_received(:save)
    end
  end

  describe "error handling" do
    context "when tournament save fails" do
      before { allow(tournament).to receive(:save).and_return(false) }

      it "logs an error" do
        expect(Rails.logger).to receive(:error).with(/Validation failed for tournament/)
        subject.process
      end
    end

    context "when golfer save fails" do
      before { allow(golfer_1).to receive(:save).and_return(false) }

      it "logs an error" do
        expect(Rails.logger).to receive(:error).with(/Validation failed for tournament/)
        subject.process
      end
    end
  end
end

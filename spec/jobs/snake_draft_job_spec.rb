require 'rails_helper'

RSpec.describe SnakeDraftJob, type: :job do
  let(:service) { instance_double(BusinessLogic::SnakeDraftService) }

  before do
    allow(BusinessLogic::SnakeDraftService).to receive(:new).and_return(service)
  end

  describe "#perform" do
    context "when draft is successful" do
      let(:tournament) { instance_double(Tournament, name: "Test Tournament") }
      let(:success_result) { { success: true, tournament: tournament, draft_order: [], assigned_picks: 32 } }

      before do
        allow(service).to receive(:execute_draft).and_return(success_result)
      end

      it "logs success message" do
        expect(Rails.logger).to receive(:info).with("Snake draft completed for tournament: Test Tournament")
        described_class.perform_now
      end
    end
  end
end

require 'rails_helper'

RSpec.describe SnakeDraftJob, type: :job do
  let(:service) { instance_double(BusinessLogic::SnakeDraftService) }

  before do
    allow(BusinessLogic::SnakeDraftService).to receive(:new).and_return(service)
  end

  describe "#perform" do
    # Tests will be added here
  end
end

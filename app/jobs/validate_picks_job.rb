class ValidatePicksJob < ApplicationJob
  queue_as :default

  def perform
    setup
    @draft_service.validate_picks
  end

  def setup
    @draft_service = BusinessLogic::DraftService.new
  end
end

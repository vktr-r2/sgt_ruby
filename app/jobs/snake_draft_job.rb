class SnakeDraftJob < ApplicationJob
  queue_as :default

  def perform
    setup
    result = @snake_draft_service.execute_draft

    if result[:success]
      Rails.logger.info "Snake draft completed for tournament: #{result[:tournament].name}"
    else
      Rails.logger.error "Snake draft failed: #{result[:error]}"
    end
  end

  def setup
    @snake_draft_service = BusinessLogic::SnakeDraftService.new
  end
end

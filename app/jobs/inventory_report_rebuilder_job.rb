class InventoryReportRebuilderJob < ApplicationJob
  queue_as :default

  def perform
    InventoryReportRebuilder.call
  end
end

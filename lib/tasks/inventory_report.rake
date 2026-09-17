# frozen_string_literal: true

namespace :inventory_report do
  desc "Rebuild all InventoryReport records from LineItem history"
  task rebuild: :environment do
    Rails.logger.info("Running inventory report...")
    InventoryReportRebuilder.call
  end
end

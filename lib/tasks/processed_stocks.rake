# frozen_string_literal: true

namespace :stocks do
  desc "Update stocks to is_processed: true if they have a processed purchase order line item"
  task update_processed_status: :environment do
    # Find stocks that have a processed purchase order line item
    stocks_to_update = StoreFronts::Stock.joins(:purchase).where.not("line_items.order_id" => nil).distinct

    # Update is_processed to true for the filtered stocks
    stocks_to_update.update_all(is_processed: true)

    Rails.logger.info("Updated #{stocks_to_update.count} stocks to is_processed: true")
  end
end

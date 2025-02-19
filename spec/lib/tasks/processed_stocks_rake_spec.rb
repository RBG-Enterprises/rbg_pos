# frozen_string_literal: true

# spec/tasks/stocks_spec.rb

require "rails_helper"
require "rake"

RSpec.describe "stocks:update_processed_status", type: :task do
  before :all do
    Rake.application.load_rakefile # Load the Rake tasks from your Rails app
  end

  let(:task) { Rake.application["stocks:update_processed_status"] }

  describe "when stocks have processed purchase order line items" do
    let!(:processed_stock) do
      create(:stock).tap do |stock|
        create(:purchase_order_line_item, stock: stock, order: create(:order))
      end
    end

    let!(:unprocessed_stock) do
      create(:stock).tap do |stock|
        create(:purchase_order_line_item, stock: stock, order_id: nil)
      end
    end

    before { task.invoke }

    it "updates only stocks with processed purchase orders to is_processed: true" do
      task.invoke
      expect(processed_stock.reload.is_processed).to be_truthy
      expect(unprocessed_stock.reload.is_processed).to be false # Ensure unprocessed stocks remain unchanged.
    end
  end
end

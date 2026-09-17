require "rails_helper"

describe InventoryReport do
  describe "associations" do
    it { is_expected.to belong_to(:stock) }
    it { is_expected.to belong_to(:product) }
    it { is_expected.to belong_to(:store_front) }
  end

  describe "validations" do
    it "enforces one report per stock" do
      report = create(:inventory_report)
      duplicate = build(:inventory_report, stock: report.stock)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:stock_id]).to be_present
    end
  end

  describe "stock association" do
    it "stock has one inventory report" do
      stock = create(:stock)
      expect(stock).to respond_to(:inventory_report)
      report = create(:inventory_report, stock: stock, product: stock.product, store_front: stock.store_front)
      expect(stock.reload.inventory_report).to eq(report)
    end
  end

  describe "database constraint" do
    it "has a unique index on stock_id" do
      indexes = ActiveRecord::Base.connection.indexes(:inventory_reports)
      unique_stock_index = indexes.find { |i| i.columns == ["stock_id"] && i.unique }
      expect(unique_stock_index).to be_present
    end
  end
end

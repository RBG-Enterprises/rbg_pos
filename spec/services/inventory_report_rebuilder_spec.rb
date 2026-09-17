require "rails_helper"

describe InventoryReportRebuilder do
  it "calculates purchases, sales, transfers and available" do
    stock = create(:stock)
    create(:purchase_order_line_item, stock: stock, quantity: 10)
    create(:sales_order_line_item, stock: stock, quantity: 2)
    create(:stock_transfer_order_line_item, stock: stock, quantity: 1)

    described_class.call

    report = InventoryReport.find_by(stock: stock)
    expect(report).to be_present
    expect(report.purchases.to_i).to eq(10)
    expect(report.sales.to_i).to eq(2)
    expect(report.transfers.to_i).to eq(1)
    expect(report.spoilage.to_i).to eq(0)
    expect(report.internal_use.to_i).to eq(0)
    expect(report.available.to_i).to eq(7)
  end

  it "calculates spoilage and internal use" do
    stock = create(:stock)
    create(:purchase_order_line_item, stock: stock, quantity: 20)
    create(:sales_order_line_item, stock: stock, quantity: 8)
    create(:spoilage_order_line_item, stock: stock, quantity: 1)
    create(:internal_use_order_line_item, stock: stock, quantity: 2)
    create(:stock_transfer_order_line_item, stock: stock, quantity: 3)

    described_class.call

    report = InventoryReport.find_by(stock: stock)
    expect(report.purchases.to_i).to eq(20)
    expect(report.sales.to_i).to eq(8)
    expect(report.spoilage.to_i).to eq(1)
    expect(report.internal_use.to_i).to eq(2)
    expect(report.transfers.to_i).to eq(3)
    expect(report.available.to_i).to eq(6)
  end

  it "calculates the full balance including returns, warranty and adjustment" do
    stock = create(:stock, count_adjustment: 2)
    create(:purchase_order_line_item, stock: stock, quantity: 10)
    create(:sales_order_line_item, stock: stock, quantity: 2)
    create(:stock_transfer_order_line_item, stock: stock, quantity: 1)
    create(:sales_return_order_line_item, stock: stock, quantity: 1)
    create(:purchase_return_order_line_item, stock: stock, quantity: 1)
    create(:for_warranty_order_line_item, stock: stock, quantity: 1)

    described_class.call

    report = InventoryReport.find_by(stock: stock)
    expect(report.sales_returns.to_i).to eq(1)
    expect(report.purchase_returns.to_i).to eq(1)
    expect(report.for_warranties.to_i).to eq(1)
    # 2 + 10 + 1 - 1 - 1 - 2 - 0 - 0 - 1 == 8, mirroring Stock#balance.
    expect(report.available.to_i).to eq(8)
  end

  it "stores the stock's product and branch" do
    stock = create(:stock)

    described_class.call

    report = InventoryReport.find_by(stock: stock)
    expect(report.product).to eq(stock.product)
    expect(report.store_front).to eq(stock.store_front)
  end

  it "is idempotent and never duplicates reports" do
    stock = create(:stock)
    create(:purchase_order_line_item, stock: stock, quantity: 10)
    create(:sales_order_line_item, stock: stock, quantity: 2)
    create(:stock_transfer_order_line_item, stock: stock, quantity: 1)

    described_class.call
    described_class.call

    expect(InventoryReport.where(stock: stock).count).to eq(1)
    report = InventoryReport.find_by(stock: stock)
    expect(report.purchases.to_i).to eq(10)
    expect(report.available.to_i).to eq(7)
  end

  it "recreates all reports after delete_all without losing history" do
    stock = create(:stock)
    create(:purchase_order_line_item, stock: stock, quantity: 10)
    create(:sales_order_line_item, stock: stock, quantity: 2)
    create(:stock_transfer_order_line_item, stock: stock, quantity: 1)
    described_class.call
    line_item_count = LineItem.count

    InventoryReport.delete_all
    expect(InventoryReport.count).to eq(0)
    expect(LineItem.count).to eq(line_item_count)

    described_class.call

    expect(InventoryReport.where(stock: stock).count).to eq(1)
    report = InventoryReport.find_by(stock: stock)
    expect(report.purchases.to_i).to eq(10)
    expect(report.sales.to_i).to eq(2)
    expect(report.transfers.to_i).to eq(1)
    expect(report.available.to_i).to eq(7)
  end

  it "does not rebuild when a LineItem is created" do
    stock = create(:stock)
    create(:purchase_order_line_item, stock: stock, quantity: 10)
    described_class.call
    expect(InventoryReport.find_by(stock: stock).purchases.to_i).to eq(10)

    create(:purchase_order_line_item, stock: stock, quantity: 5)

    # No automatic rebuild: report stays stale until rebuilder runs.
    expect(InventoryReport.find_by(stock: stock).reload.purchases.to_i).to eq(10)
  end
end

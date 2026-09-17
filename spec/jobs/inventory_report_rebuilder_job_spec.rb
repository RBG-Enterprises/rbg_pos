require "rails_helper"

describe InventoryReportRebuilderJob do
  it "rebuilds reports via the rebuilder" do
    stock = create(:stock)
    create(:purchase_order_line_item, stock: stock, quantity: 10)

    expect { described_class.perform_now }.to change { InventoryReport.count }.from(0).to(1)
    expect(InventoryReport.find_by(stock: stock).purchases.to_i).to eq(10)
  end

  it "is queued on the default queue" do
    expect(described_class.queue_name).to eq("default")
  end
end

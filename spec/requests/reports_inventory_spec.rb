require "rails_helper"

describe "StoreFrontModule::StoreFronts::Inventories CSV", type: :request do
  it "returns one row per stock with required columns, filtered by branch" do
    business = create(:business)
    store_front = create(:store_front, business: business)
    user = create(:proprietor, business: business, store_front: store_front)
    login_as(user, scope: :user)

    product = create(:product, name: "iPhone", business: user.business)
    other_branch = create(:store_front, business: user.business)

    stock_a = create(:stock, product: product, store_front: user.store_front, barcode: "111")
    stock_b = create(:stock, product: product, store_front: user.store_front, barcode: "222", count_adjustment: 3)
    other_stock = create(:stock, product: product, store_front: other_branch, barcode: "999")

    create(:purchase_order_line_item, stock: stock_a, product: product, quantity: 10)
    create(:sales_order_line_item, stock: stock_a, product: product, quantity: 2)
    create(:stock_transfer_order_line_item, stock: stock_a, product: product, quantity: 1)
    create(:sales_return_order_line_item, stock: stock_a, product: product, quantity: 1)

    create(:purchase_order_line_item, stock: stock_b, product: product, quantity: 5)
    create(:sales_order_line_item, stock: stock_b, product: product, quantity: 1)

    create(:purchase_order_line_item, stock: other_stock, product: product, quantity: 100)

    InventoryReportRebuilder.call

    get "/store_front_module/store_fronts/#{user.store_front.id}/inventories.csv"

    expect(response).to be_successful
    expect(response.headers["Content-Type"]).to include("text/csv")
    expect(response.headers["Content-Disposition"]).to include("inventory-report-")
    expect(response.headers["Content-Disposition"]).to include(".csv")

    csv = CSV.parse(response.body)
    expect(csv.first).to eq(["Product", "SKU", "Purchases", "Sales", "Spoilage", "Internal Use", "Transfers", "Sales Returns", "Purchase Returns", "For Warranty", "Adjustment", "Available"])

    rows = csv[1..]
    skus = rows.map { |r| r[1] }
    # Same product appears on multiple rows (one per stock), other branch excluded.
    expect(skus).to contain_exactly("111", "222")

    row_a = rows.find { |r| r[1] == "111" }
    expect(row_a[0]).to eq("iPhone")
    expect(row_a[2].to_i).to eq(10)
    expect(row_a[3].to_i).to eq(2)
    expect(row_a[4].to_i).to eq(0)
    expect(row_a[5].to_i).to eq(0)
    expect(row_a[6].to_i).to eq(1)
    expect(row_a[7].to_i).to eq(1)
    expect(row_a[8].to_i).to eq(0)
    expect(row_a[9].to_i).to eq(0)
    expect(row_a[10].to_i).to eq(0)
    expect(row_a[11].to_i).to eq(8)

    row_b = rows.find { |r| r[1] == "222" }
    expect(row_b[2].to_i).to eq(5)
    expect(row_b[10].to_i).to eq(3)
    expect(row_b[11].to_i).to eq(7)
  end

  it "reads from InventoryReport without aggregating LineItems during export" do
    business = create(:business)
    store_front = create(:store_front, business: business)
    user = create(:proprietor, business: business, store_front: store_front)
    login_as(user, scope: :user)
    stock = create(:stock, product: create(:product, business: user.business), store_front: user.store_front, barcode: "333")
    create(:purchase_order_line_item, stock: stock, quantity: 20)
    InventoryReportRebuilder.call

    expect(LineItem).not_to receive(:group)
    get "/store_front_module/store_fronts/#{user.store_front.id}/inventories.csv"
    expect(response).to be_successful
  end
end

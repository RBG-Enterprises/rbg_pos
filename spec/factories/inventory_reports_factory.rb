FactoryBot.define do
  factory :inventory_report do
    association :stock
    product { stock.product }
    store_front { stock.store_front }
    purchases { 0 }
    sales { 0 }
    spoilage { 0 }
    internal_use { 0 }
    transfers { 0 }
    sales_returns { 0 }
    purchase_returns { 0 }
    for_warranties { 0 }
    available { 0 }
  end
end

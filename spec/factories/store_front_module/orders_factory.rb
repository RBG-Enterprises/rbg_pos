# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    association :store_front
    association :employee, factory: :user
    account_number { SecureRandom.uuid }
    factory :stock_transfer_order, class: "StoreFrontModule::Orders::StockTransferOrder" do
    end

    factory :internal_use_order, class: "StoreFrontModule::Orders::InternalUseOrder" do
    end
    factory :spoilage_order, class: "StoreFrontModule::Orders::SpoilageOrder" do
    end

    factory :purchase_return_order, class: "StoreFrontModule::Orders::PurchaseReturnOrder" do
    end

    factory :sales_return_order, class: "StoreFrontModule::Orders::SalesReturnOrder" do
    end

    factory :for_warranty_order, class: "StoreFrontModule::Orders::ForWarrantyOrder" do
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :sales_order, class: "StoreFrontModule::Orders::SalesOrder" do
    association :store_front
    association :employee, factory: :user
    association :commercial_document, factory: :customer
    account_number { SecureRandom.uuid }
    association :sales_revenue_account, factory: :revenue
    association :receivable_account, factory: :asset
    association :sales_discount_account, factory: :revenue
  end
end

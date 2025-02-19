# frozen_string_literal: true

merchandise_inventory_account = AccountingModule::Asset.create!(name: "Merchandise Inventory", account_code: "1001", business_id: 1)
cost_of_goods_sold_account = AccountingModule::Expense.create!(name: "Cost of Goods Sold", account_code: "5001", business_id: 1)
accounts_payable_to_suppliers =  AccountingModule::Liability.create!(name: "Accounts Payable to Suppliers", account_code: "2001", business_id: 1)
cash_on_hand_account = AccountingModule::Asset.create!(name: "Cash on Hand", account_code: "1002", business_id: 1)
sales_discount_account = AccountingModule::Revenue.create!(name: "Sales Discount", account_code: "4001", contra: true, business_id: 1)
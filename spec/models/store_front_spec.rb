require 'rails_helper'

describe StoreFront do
  describe 'associations' do
    it { is_expected.to belong_to(:service_receivable_account_category).optional }
    it { is_expected.to belong_to(:sales_revenue_account_category).optional }
    it { is_expected.to belong_to :business }
    it { is_expected.to belong_to :merchandise_inventory_account }
    it { is_expected.to belong_to(:sales_account).optional }
    it { is_expected.to belong_to(:sales_discount_account).optional }
    it { is_expected.to belong_to :cost_of_goods_sold_account }
    it { is_expected.to belong_to(:receivable_account).optional }
    it { is_expected.to belong_to(:internal_use_account).optional }
    it { is_expected.to belong_to(:purchase_return_account).optional }
    it { is_expected.to belong_to(:spoilage_account).optional }
    it { is_expected.to belong_to(:service_revenue_account).optional }
    it { is_expected.to have_many :sales_orders }
    it { is_expected.to have_many :delivered_stock_transfer_orders }
    it { is_expected.to have_many :delivered_stock_transfers }
    it { is_expected.to have_many :selling_prices }
    it { is_expected.to have_many :employees }
    it { is_expected.to have_many :store_front_accounts }
    it { is_expected.to have_many :accounts }
    it { is_expected.to have_many :stocks }
    it { is_expected.to have_many :level_one_account_categories }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :name }
  end
  describe 'delegations' do
    it { is_expected.to delegate_method(:name).to(:business).with_prefix }
  end

  it "#payable_account" do
    merchandise_inventory_account = create(:asset)
    store_front = create(:store_front, merchandise_inventory_account: merchandise_inventory_account)

    expect(store_front.payable_account).to eql merchandise_inventory_account
  end
end

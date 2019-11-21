module StoreFronts
  class Stock < ApplicationRecord
    include PgSearch::Model
    pg_search_scope :barcode_search, against: [:barcode]
    pg_search_scope :text_search, against: [:barcode], associated_against: { product: [:name] }
    belongs_to :store_front
    belongs_to :product
    belongs_to :unit_of_measurement, class_name: 'StoreFrontModule::UnitOfMeasurement'
    has_one    :purchase,            class_name: 'StoreFrontModule::LineItems::PurchaseOrderLineItem'
    has_many   :sales,               class_name: 'StoreFrontModule::LineItems::SalesOrderLineItem',          extend: StockBalanceFinder
    has_many   :stock_transfers,     class_name: 'StoreFrontModule::LineItems::StockTransferOrderLineItem',  extend: StockBalanceFinder
    has_many   :internal_uses,       class_name: 'StoreFrontModule::LineItems::InternalUseOrderLineItem',    extend: StockBalanceFinder
    has_many   :spoilages,           class_name: 'StoreFrontModule::LineItems::SpoilageOrderLineItem',       extend: StockBalanceFinder
    has_many   :purchase_returns,    class_name: 'StoreFrontModule::LineItems::PurchaseReturnOrderLineItem', extend: StockBalanceFinder
    has_many   :for_warranties,      class_name: 'StoreFrontModule::LineItems::ForWarrantyOrderLineItem',    extend: StockBalanceFinder
    has_many   :sales_returns,       class_name: 'StoreFrontModule::LineItems::SalesReturnOrderLineItem',    extend: StockBalanceFinder
    has_many   :line_items,          dependent: :nullify, extend: StockBalanceFinder

    delegate :name,           to: :product
    delegate :unit_code,      to: :unit_of_measurement
    delegate :purchase_order, :unit_cost,  to: :purchase
    delegate :supplier,       to: :purchase_order, allow_nil: true
    delegate :name,           to: :supplier,       prefix: true
    delegate :date,           to: :purchase_order, prefix: true, allow_nil: true
    delegate :quantity,       to: :purchase, prefix: true

    def self.to_csv
     attributes = %w{name barcode purchase_quantity sales_balance stock_transfers_balance spoilage_balance internal_uses_balance purchase_returns_balance available_quantity}

     CSV.generate(headers: true) do |csv|
       csv << attributes

       all.each do |user|
         csv << attributes.map{ |attr| user.send(attr) }
       end
     end
   end

    def self.available
      where(available: true)
    end

    def self.available_quantity
      sum(&:available_quantity)
    end

    def self.processed
      joins(:purchase).where.not('line_items.order_id' => nil)
    end

    def balance_for_cart(cart)
      balance - sales.unprocessed.where(cart: cart).sum(:quantity)
    end

    def balance_for_cart_on_transfer(cart)
      balance - stock_transfers.processed.where(cart: cart).sum(&:quantity)
    end

    def balance
      purchase_quantity        +
      sales_returns_balance    -
      purchase_returns_balance -
      stock_transfers_balance  -
      sales_balance  -
      internal_uses_balance    -
      spoilages_balance
    end

    def sold?
      balance.zero? && sales.present?
    end

    def latest_selling_price(store_front)
      unit_of_measurement.selling_prices.where(store_front: store_front).current_price
    end

    def last_purchase_cost
      purchase_unit_cost
    end

    def total_cost
      purchase_quantity * last_purchase_cost
    end

    def sales_balance
      sales.processed.balance
    end

    def sales_returns_balance
      sales_returns.processed.balance
    end

    def stock_transfers_balance
      stock_transfers.processed.balance
    end

    def spoilages_balance
      spoilages.processed.balance
    end

    def internal_uses_balance
      internal_uses.processed.balance
    end

    def purchase_returns_balance
      purchase_returns.processed.balance
    end

    def update_available_quantity
      ::StoreFronts::StockQuantityUpdater.new(stock: self).update_available_quantity!
    end

  end
end

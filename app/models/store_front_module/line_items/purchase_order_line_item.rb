 module StoreFrontModule
  module LineItems
    class PurchaseOrderLineItem < LineItem
      pg_search_scope :text_search, against: [:bar_code], :associated_against => {:product => [:name] }
      belongs_to :purchase_order,                     class_name: "StoreFrontModule::Orders::PurchaseOrder", foreign_key: 'order_id', optional: true
      has_many :referenced_purchase_order_line_items, class_name: "StoreFrontModule::LineItems::ReferencedPurchaseOrderLineItem", foreign_key: 'purchase_order_line_item_id', dependent: :destroy
    has_many :sales_order_line_items,               through: :referenced_purchase_order_line_items, class_name: 'StoreFrontModule::LineItems::SalesOrderLineItem', source: :sales_order_line_item
      has_many :purchase_return_order_line_items,     class_name: "StoreFrontModule::LineItems::PurchaseReturnOrderLineItem", foreign_key: 'purchase_order_line_item_id'
      has_many :internal_use_order_line_items,        class_name: "StoreFrontModule::LineItems::InternalUseOrderLineItem", foreign_key: 'purchase_order_line_item_id'
      has_many :stock_transfer_order_line_items,      class_name: "StoreFrontModule::LineItems::StockTransferOrderLineItem", foreign_key: 'purchase_order_line_item_id',  dependent: :destroy

      has_many :sales_return_order_line_items, class_name: "StoreFrontModule::LineItems::SalesReturnOrderLineItem", foreign_key: 'purchase_order_line_item_id'
      delegate :supplier, :origin_store_front_name, :destination_store_front_name, :stock_transfer?,  to: :purchase_order, allow_nil: true
      delegate :business_name, to: :supplier, prefix: true, allow_nil: true

      def self.for_store_front(store_front)
        joins(:purchase_order).where('orders.destination_store_front_id' => store_front.id)
      end

      def self.stock_transfers
        joins(:purchase_order).
        where('orders.supplier_type' => "StoreFront")
      end

      def self.purchases_and_stock_transfers(store_front)
        all.processed
      end

      def self.not_stock_transfers
        joins(:purchase_order).
        where.not('orders.supplier_type' => "StoreFront")
      end

      def self.delivered_stock_transfers(args={})
        joins(:purchase_order).
        where('orders.supplier_type' => "StoreFront").
        where('orders.supplier_id' => args[:store_front].id)
      end

      def self.processed
        where.not(order_id: nil)
      end
      def processed?
        order_id.present?
      end

      def self.available
        select { |a| !a.out_of_stock? }
      end
      def sold?
        referenced_purchase_order_line_items &&  out_of_stock?
      end

      def date_sold
        referenced_purchase_order_line_items.last.try(:sales_order_line_item).try(:order).try(:date)

      end



      def out_of_stock?
        available_quantity <= 0
      end

      def sold_quantity(args={})
        sales_order_line_items.processed.total
      end

      def customer
        StoreFrontModule::LineItems::ReferencedPurchaseOrderLineItem.where(purchase_order_line_item_id: self.id).first.try(:sales_order_line_item).try(:order).try(:customer).try(:name)
      end

      def purchase_returns_quantity(args={})
        purchase_return_order_line_items.processed.total
      end

      def available_quantity(args={})
        sales_returns_quantity(args) +
        quantity -
        sold_quantity(args) -
        purchase_returns_quantity(args) -
        internal_uses_quantity(args) -
        stock_transfers_quantity(args)
      end

      def internal_uses_quantity(args={})
        internal_use_order_line_items.processed.total
      end

      def stock_transfers_quantity(args={})
        if args[:store_front].present?
          stock_transfer_order_line_items.processed.for_store_front(args[:store_front]).total
        else
          stock_transfer_order_line_items.processed.total
        end
      end

      def sales_returns_quantity(args={})
        if args[:store_front].present?
          sales_return_order_line_items.processed.for_store_front(args[:store_front]).total
        else
          sales_return_order_line_items.processed.total
        end
      end

      def purchase_cost
        return unit_cost if unit_of_measurement.blank?
        if unit_of_measurement.present? && unit_of_measurement.base_measurement?
          unit_cost
        else
          unit_cost / unit_of_measurement.conversion_multiplier
        end
      end
    end
  end
end

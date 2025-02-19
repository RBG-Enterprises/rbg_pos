module StoreFrontModule
  module Orders
    class PurchaseOrderProcessing
      include ActiveModel::Model
      attr_accessor  :cart_id, :supplier_id, :voucher_id, :employee_id, :date, :registry_id, :account_number
      validates :voucher_id, :supplier_id, :account_number, :cart_id, presence: true
      # validate :amounts_cancel?


      def process!
        ActiveRecord::Base.transaction do
          create_purchase_order
          remove_cart_reference
          update_stocks_to_processed
          create_purchase_prices
        end
      end

      private
      def create_purchase_order
      order = StoreFrontModule::Orders::PurchaseOrder.new(
        supplier:                find_supplier,
        date:                    date,
        store_front:             find_employee.store_front,
        destination_store_front: find_employee.store_front,
        account_number:          account_number,
        voucher:                 find_voucher,
        search_term:             find_supplier.business_name,
        employee:                find_employee)
        create_accounts(order)
        order.save!
      end

      def remove_cart_reference
        find_cart.purchase_order_line_items.each do |line_item|
          line_item.update!(date: date)
          line_item.cart_id = nil
          find_order.purchase_order_line_items << line_item
        end
        if find_registry.present?
          find_registry.purchase_order_line_items.each do |line_item|
            line_item.update!(date: date)
            line_item.cart_id = nil
            find_order.purchase_order_line_items << line_item
          end
        end
      end

      def update_stocks_to_processed
        find_order.purchase_order_line_items.each do |line_item|
          line_item.stock.update!(is_processed: true)
        end
      end

      def create_accounts(order)
        ::AccountCreators::PurchaseOrder.new(purchase_order: order).create_accounts!
      end

      def create_purchase_prices
        find_order.purchase_order_line_items.each do |line_item|
          StoreFrontModule::PurchasePrice.create!(
            product: line_item.product,
            price: line_item.unit_cost,
            date: find_order.date,
            unit_of_measurement: line_item.unit_of_measurement,
            store_front: find_employee.store_front
          )
        end
      end

      def find_order
        StoreFrontModule::Orders::PurchaseOrder.find_by(account_number: account_number)
      end
      def find_supplier
        Supplier.find(supplier_id)
      end
      def find_voucher
        Voucher.find(voucher_id)
      end
      def find_cart
        Cart.find(cart_id)
      end
      def find_employee
        User.find(employee_id)
      end
      def find_registry
        StoreFrontModule::Registries::PurchaseOrderRegistry.find_by_id(registry_id)
      end

      private
      # def amounts_cancel?
      #     errors[:voucher_id] << "The total amount and voucher amount is not equal" if find_voucher.total != find_cart.purchase_order_line_items.sum(&:total_cost)
      # end
    end
  end
end

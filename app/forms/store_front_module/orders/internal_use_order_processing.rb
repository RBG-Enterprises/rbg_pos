module StoreFrontModule
  module Orders
    class InternalUseOrderProcessing
      include ActiveModel::Model
      attr_accessor  :cart_id,
                     :employee_id,
                     :date,
                     :description,
                     :reference_number,
                     :commercial_document_id
      validates :description, :date, presence: true

      def process!
        ActiveRecord::Base.transaction do
          create_stock_transfer_order
        end
      end

      private
      def create_stock_transfer_order
        order = StoreFrontModule::Orders::InternalUseOrder.create!(
          date: date,
          account_number: SecureRandom.uuid,
          store_front: find_employee.store_front,
          description: description,
          employee: find_employee,
          commercial_document: find_commercial_document,
          search_term: find_employee.name,
          reference_number: reference_number)
        find_cart.internal_use_order_line_items.each do |line_item|
          line_item.update!(date: date)
          line_item.cart_id = nil
          order.internal_use_order_line_items << line_item
        end
        create_entry(order)
        update_stock_available_quantity(order)
      end

      def find_commercial_document
        User.find_by_id(commercial_document_id)
      end

      def find_cart
        Cart.find_by_id(cart_id)
      end

      def find_employee
        User.find_by_id(employee_id)
      end

      def update_stock_available_quantity(order)
        order.stocks.each do |stock|
          stock.update_available_quantity!
        end
      end

      def create_entry(order)
        merchandise_inventory = find_employee.store_front.merchandise_inventory_account
        internal_use_expenses = find_employee.store_front.internal_use_account
        find_employee.entries.create!(
          recorder: find_employee,
          commercial_document: find_employee,
          entry_date: date,
          description: description,
          debit_amounts_attributes: [amount: order.total_cost,
                                        account: internal_use_expenses
                                      ],
            credit_amounts_attributes:[ amount: order.total_cost,
                                        account: merchandise_inventory
                                     ])
      end
    end
  end
end

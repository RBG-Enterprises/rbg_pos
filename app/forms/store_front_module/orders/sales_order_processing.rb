module StoreFrontModule
  module Orders
    class SalesOrderProcessing
      include ActiveModel::Model
      attr_accessor  :customer_id,
                     :date,
                     :cash_tendered,
                     :order_change,
                     :discount_amount,
                     :employee_id,
                     :cart_id,
                     :reference_number,
                     :account_number,
                     :cash_register_session_id
      validates :cart_id,
                :employee_id,
                :customer_id,
                :cash_tendered,
                :discount_amount,
                :order_change,
                presence: true

      def find_order
        StoreFrontModule::Orders::SalesOrder.find_by(account_number: account_number)
      end

      def process!
        ActiveRecord::Base.transaction do
          create_sales_order
          create_sales_line_items
        end
      end

       def find_cart
        Cart.find(cart_id)
      end

      private
      def create_sales_order
          order = StoreFrontModule::Orders::SalesOrder.create!(
          date:                date,
          employee:            find_employee,
          store_front:         find_employee.store_front,
          commercial_document: find_customer,
          account_number:      account_number,
          search_term:         find_customer.name,
          reference_number:    reference_number,
          cash_register_session_id: cash_register_session_id)

          CashPayment.create!(
            cash_paymentable: order,
            cash_tendered:    cash_tendered,
            cash_change:      order_change,
            discount_amount:  discount_amount)
            create_accounts(order)
        end

        def create_sales_line_items
          find_cart.sales_order_line_items.each do |sales_order_line_item|
            sales_order_line_item.update(date: date)
            sales_order_line_item.cart_id = nil
            find_order.sales_order_line_items << sales_order_line_item
        end

      end
      def find_customer
        Customer.find(customer_id)
      end
      def find_employee
        User.find(employee_id)
      end
      def create_accounts(order)
        AccountCreators::SalesOrder.new(sales_order: order).create_accounts!
      end
    end
  end
end

module RepairServicesModule
  class RepairServiceOrderProcessing
    include ActiveModel::Model
    attr_accessor :customer_id,
                  :employee_id,
                  :cart_id,
                  :date,
                  :work_order_id,
                  :reference_number

    validates :customer_id,
              :date,
              :reference_number,
              :cart_id,
              :employee_id,
              :work_order_id,
              presence: true

    def process!
      if valid?
        ApplicationRecord.transaction do
          create_repair_service_order
        end
      end
    end

    private

    def create_repair_service_order
      order  = find_work_order.sales_orders.create!(
        date:             date,
        store_front:      find_work_order.store_front,
        account_number:   SecureRandom.uuid,
        reference_number: reference_number,
        search_term:      find_customer.name,
        employee:         find_employee)

      find_cart.sales_order_line_items.each do |sales_order_line_item|
        sales_order_line_item.cart_id = nil
        order.sales_order_line_items << sales_order_line_item
      end
      create_entry(order)
      create_accounts(order)
    end
    def create_accounts(order)
      AccountCreators::SalesOrder.new(sales_order: order).create_accounts!
    end
    def create_entry(order)
      EntryCreators::Orders::RepairServiceOrder.new(sales_order: order, work_order: find_work_order, employee: find_employee).create_entry!
    end

      def find_customer
        Customer.find(customer_id)
      end

      def find_employee
        User.find(employee_id)
      end

      def find_cart
        Cart.find(cart_id)
      end
      def find_store_front
        find_employee.store_front
      end

      def find_work_order
        WorkOrder.find(work_order_id)
      end
  end
end

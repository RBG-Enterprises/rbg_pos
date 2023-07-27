module Orders
  module SalesOrders
    module SalesOrderLineItems
      class Cancellation
        attr_reader :line_item, :order, :employee

        def initialize(args)
          @employee  = args.fetch(:employee)
          @line_item = args.fetch(:line_item)
          @order     = @line_item.sales_order
        end

        def cancel!
          ActiveRecord::Base.transaction do
            create_entry
            delete_item
            update_stock_available_quantity
          end
        end

        def create_entry
          store_front           = order.store_front
          accounts_receivable   = order.receivable_account
          cost_of_goods_sold    = store_front.cost_of_goods_sold_account
          sales                 = order.sales_revenue_account
          sales_discount        = order.default_sales_discount_account
          merchandise_inventory = store_front.merchandise_inventory_account
          employee.entries.create!(
            commercial_document: order.customer,
            entry_date: Date.current,
            description: "Sales Return - #{order.account_number}",
            credit_amounts_attributes: [{ amount: line_item.total_cost,
                                          account: credit_account},
                                        { amount: line_item.cost_of_goods_sold,
                                          account: cost_of_goods_sold} ],
              debit_amounts_attributes:[{amount: line_item.total_cost,
                                          account: sales},
                                         { amount: line_item.cost_of_goods_sold,
                                          account: merchandise_inventory}])
        end

        def delete_item
          line_item.destroy
        end

        def update_stock_available_quantity
          stock.update_available_quantity!
        end

        def credit_account
          if order.receivable_account.balance.zero?
            order.employee.cash_on_hand_account
          else
            order.default_receivable_account
          end
        end
      end
    end
  end
end

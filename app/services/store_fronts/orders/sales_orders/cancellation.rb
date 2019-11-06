module StoreFronts
  module Orders
    module SalesOrders
      class Cancellation
        attr_reader :sales_order, :voucher, :receivable_account, :sales_revenue_account, :entry

        def initialize(sales_order:)
          @sales_order           = sales_order
          @voucher               = @sales_order.voucher
          @entry                 = @voucher.entry
          @receivable_account    = @sales_order.receivable_account
          @sales_revenue_account = @sales_order.sales_revenue_account
        end

        def cancel!
          ActiveRecord::Base.transaction do
            delete_line_items!
            
            delete_order!

            delete_voucher!
            delete_entries!
            delete_accounts!
          end
        end

        private

        def delete_entries!
          entry.destroy
          receivable_account.entries.destroy_all
          sales_revenue_account.entries.destroy_all
        end

        def delete_accounts!
          receivable_account.destroy
          sales_revenue_account.destroy
        end

        def delete_line_items!
          sales_order.sales_order_line_items.destroy_all
        end

        def delete_order!
          sales_order.destroy
        end

        def delete_voucher!
          voucher.voucher_amounts.destroy_all
          voucher.destroy
        end
      end
    end
  end
end

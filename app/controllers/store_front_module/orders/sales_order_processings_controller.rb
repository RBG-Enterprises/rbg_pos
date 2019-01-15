module StoreFrontModule
  module Orders
    class SalesOrderProcessingsController < ApplicationController
      def create
        @sales_order = StoreFrontModule::Orders::SalesOrderProcessing.new(order_params)
        if @sales_order.valid?
          ActiveRecord::Base.transaction do
            @sales_order.process!
            @processed_order = @sales_order.find_order
            create_voucher
            create_entry
            update_order
          end
          redirect_to store_index_url, notice: "Order saved successfully."
        else
          redirect_to store_index_url, alert: "Error"
        end
      end

      private
      def create_voucher
        Vouchers::SalesOrderVoucher.new(order: @processed_order, employee: current_user).create_voucher!
      end

      def create_entry
        VoucherEntryCreation.new(voucher: Voucher.find_by(account_number: @processed_order.account_number)).create_entry!
      end

      def update_order
        @processed_order.update_attributes!(store_front: current_user.store_front, voucher: @voucher_processing)
      end

      def order_params
        params.require(:store_front_module_orders_sales_order_processing).
        permit(:customer_id,
               :date,
               :cash_tendered,
               :order_change,
               :employee_id,
               :cart_id,
               :discount_amount,
               :account_number,
               :reference_number)
      end
    end
  end
end

module StoreFrontModule
  module Orders
    class SalesOrderProcessingsController < ApplicationController
      def create
        @sales_order = StoreFrontModule::Orders::SalesOrderProcessing.new(order_params.merge(cash_register_session_id: current_cash_register_session.try(:id)))
        if @sales_order.valid?
          ActiveRecord::Base.transaction do
            @sales_order.process!
            @processed_order = @sales_order.find_order
            create_voucher
            update_stock_available_quantity
          end
          redirect_to store_front_module_sales_order_processing_path(@processed_order.voucher), notice: "Review and confirm the sale."
        else
          redirect_to store_index_url, alert: "Error"
        end
      end

      def show
        @voucher = Voucher.find(params[:id])
        @order = @voucher.commercial_document
      end

      private
      def create_voucher
        Vouchers::SalesOrderVoucher.new(order: @processed_order, employee: current_user, voucher_class: Vouchers::CashSaleVoucher).create_voucher!
      end

      def update_stock_available_quantity
        @processed_order.stocks.each do |stock|
          stock.update_available_quantity!
        end
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

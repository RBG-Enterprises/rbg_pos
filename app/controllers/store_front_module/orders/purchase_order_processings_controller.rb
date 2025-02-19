# frozen_string_literal: true

module StoreFrontModule
  module Orders
    class PurchaseOrderProcessingsController < ApplicationController
      def create
        @purchase_order = StoreFrontModule::Orders::PurchaseOrderProcessing.new(order_params)
        if @purchase_order.valid?
          @purchase_order.process!
          redirect_to store_front_module_purchase_orders_url, notice: "Purchase Order saved successfully"
        else
          redirect_to new_store_front_module_purchase_order_line_item_processing_url,
            alert: "Error. Check amounts are equal and the voucher is issued to the supplier."
        end
      end

      private

      def order_params
        params.require(:store_front_module_orders_purchase_order_processing)
          .permit(:date, :supplier_id, :voucher_id, :cart_id, :employee_id, :registry_id, :account_number)
      end
    end
  end
end

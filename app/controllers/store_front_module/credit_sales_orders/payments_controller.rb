module StoreFrontModule
  module CreditSalesOrders
    class PaymentsController < ApplicationController
      def new
        @order = StoreFrontModule::Orders::SalesOrder.find(params[:credit_sales_order_id])
        @payment = StoreFrontModule::Payments::CreditSalesOrderPaymentProcessing.new
      end
      def create
        @order = StoreFrontModule::Orders::SalesOrder.find(params[:credit_sales_order_id])
        @payment = StoreFrontModule::Payments::CreditSalesOrderPaymentProcessing.new(payment_params)
        if @payment.valid?
          @payment.process!
          redirect_to store_front_module_credit_sales_order_payment_path(@order, @payment.voucher),
                      notice: "Review and confirm the payment."
        else
          render :new
        end
      end

      def show
        @order = StoreFrontModule::Orders::SalesOrder.find(params[:credit_sales_order_id])
        @voucher = Voucher.find(params[:id])
      end

      private
      def payment_params
        params.require(:store_front_module_payments_credit_sales_order_payment_processing).
        permit(:order_id, :employee_id, :date, :amount, :expense_amount, :expense_account_id, :reference_number, :description, :cash_on_hand_account_id)
      end
    end
  end
end

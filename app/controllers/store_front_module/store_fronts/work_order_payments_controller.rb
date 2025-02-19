module StoreFrontModule
  module StoreFronts
    class WorkOrderPaymentsController < ApplicationController
      def index
        @store_front = current_business.store_fronts.find(params[:store_front_id])
        @from_date = params[:from_date].present? ? Date.parse(params[:from_date]) : Date.current.beginning_of_month
        @to_date = params[:to_date].present? ? Date.parse(params[:to_date]) : Date.current.end_of_month
        @entries = @store_front.work_orders.payment_entries.entered_on(from_date: @from_date, to_date: @to_date)
        respond_to do |format|
          format.xlsx
        end
      end
    end
  end
end

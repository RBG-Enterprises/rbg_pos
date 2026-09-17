module StoreFrontModule
  class StoreFrontsController < ApplicationController
    def index
      @business = current_user.business
      @store_fronts = @business.store_fronts
      @from_date   = params[:from_date] ? DateTime.parse(params[:from_date]) : Date.current
      @to_date   = params[:to_date] ? DateTime.parse(params[:to_date]) : Date.current
    end
    def show
      @store_front = current_user.business.store_fronts.find(params[:id])
      @from_date   = params[:from_date] ? DateTime.parse(params[:from_date]) : Date.current
      @to_date   = params[:to_date] ? DateTime.parse(params[:to_date]) : Date.current
      @as_of_date  = params[:as_of_date] ? Date.parse(params[:as_of_date]) : Date.current
    end
  end
end

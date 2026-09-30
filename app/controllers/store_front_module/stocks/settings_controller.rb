# frozen_string_literal: true

module StoreFrontModule
  module Stocks
    class SettingsController < ApplicationController
      include StockOverview

      before_action :ensure_proprietor

      def index
        @stock = current_store_front.stocks
          .includes(:product, :unit_of_measurement, purchase: { purchase_order: :supplier })
          .find(params[:stock_id])
        load_stock_overview
      end

      private

      def ensure_proprietor
        redirect_to store_front_module_stock_path(params[:stock_id]),
          alert: "You are not authorized to view this page." unless current_user.proprietor?
      end
    end
  end
end

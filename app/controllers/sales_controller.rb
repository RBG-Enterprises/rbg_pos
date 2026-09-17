class SalesController < ApplicationController
  RANGES = %w[today yesterday week last_week month last_month quarter last_quarter ytd last_year].freeze
  CASHIER_EMAILS = ['elmie@rbg.com','analyn.perez@rbg.com','nova@rbg.com', 'jenelyn.lamut@rbg.com', 'jonalyn.lagawe@rbgtech.co', 'nathalie@rbg.com', 'ronald.quirino.sales_clerk@rbg.com'].freeze

  before_action :require_proprietor

  def index
    @range = RANGES.include?(params[:range]) ? params[:range] : 'today'
    @from_date, @to_date = date_range_for(@range)

    @sales_clerks = User.sales_clerk.includes(:store_front, :cash_on_hand_account).where(email: CASHIER_EMAILS)

    @sales_by_cashier = @sales_clerks.each_with_object({}) do |sales_clerk, hash|
      cash_sales = sales_clerk.cash_on_hand_account&.debits_balance(from_date: @from_date.beginning_of_day, to_date: @to_date.end_of_day) || 0
      credit_sales = sales_clerk.sales_orders
        .ordered_on(from_date: @from_date.beginning_of_day, to_date: @to_date.end_of_day)
        .where.missing(:cash_payment)
        .to_a.sum(&:total_cost)

      hash[sales_clerk.full_name] = { cash: cash_sales, credit: credit_sales, total: cash_sales + credit_sales }
    end
  end

  private

  def date_range_for(range)
    case range
    when 'yesterday'
      [Date.yesterday, Date.yesterday]
    when 'week'
      [Date.current.beginning_of_week, Date.current.end_of_week]
    when 'last_week'
      last_week = Date.current.beginning_of_week - 1.week
      [last_week.beginning_of_week, last_week.end_of_week]
    when 'month'
      [Date.current.beginning_of_month, Date.current.end_of_month]
    when 'last_month'
      last_month = Date.current.beginning_of_month - 1.month
      [last_month.beginning_of_month, last_month.end_of_month]
    when 'quarter'
      [Date.current.beginning_of_quarter, Date.current.end_of_quarter]
    when 'last_quarter'
      last_quarter = Date.current.beginning_of_quarter - 3.months
      [last_quarter.beginning_of_quarter, last_quarter.end_of_quarter]
    when 'ytd'
      [Date.current.beginning_of_year, Date.current]
    when 'last_year'
      last_year = Date.current.beginning_of_year - 1.year
      [last_year.beginning_of_year, last_year.end_of_year]
    else
      [Date.current, Date.current]
    end
  end

  def require_proprietor
    redirect_to store_index_path, alert: "You are not authorized to view this page." unless current_user.proprietor?
  end
end

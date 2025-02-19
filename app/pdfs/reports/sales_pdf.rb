module Reports
  class SalesPdf < Prawn::Document
    attr_reader :from_date, :to_date, :orders, :employee, :view_context, :business, :cash_on_hand_account, :store_front
    def initialize(args)
      super(margin: 30, page_size: 'A4')
      @from_date    = args[:from_date]
      @to_date      = args[:to_date]
      @orders       = args[:orders]
      @employee     = args[:employee]
      @store_front  = args[:store_front]
      @cash_on_hand_account = args[:cash_on_hand_account]
      @business     = args[:business]
      @view_context = args[:view_context]
      heading
      cash_on_hand_account_details

      orders_table
    end
    private
    def price(number)
      @view_context.number_to_currency(number, :unit => "P ")
    end
    def order_description(order)
      if order.line_items.present?
        order.line_items_name
      elsif order.description.present?
        order.description
      end
    end
    def heading
      bounding_box [360, 770], width: 200 do
        text "#{business.name.upcase }", style: :bold, size: 12
    end
    bounding_box [0, 770], width: 400 do
      text "SALES REPORT", style: :bold, size: 12
      if from_date == to_date
        text "Date: #{from_date.strftime("%b. %e, %Y")}", size: 10
      else
        text "Date Covered: #{from_date.strftime("%b. %e, %Y")} - #{to_date.strftime("%b. %e, %Y")}", size: 10
      end

      if store_front.present?
        text "Branch: #{store_front.name}", style: :bold, size: 10
      end

    end
      move_down 10
      stroke_horizontal_rule
    end
    def cash_on_hand_account_details
      if employee.present?
        table([["EMPLOYEE ", "#{employee.try(:name)}"]], cell_style: { size: 9, font: "Helvetica", :inline_format => true}, column_widths: [120, 150, 150, 100]) do
          cells.borders = []
        end

        table([["CASH ACCOUNT", "#{cash_on_hand_account.try(:name)}"]], cell_style: { size: 9, font: "Helvetica", :inline_format => true}, column_widths: [120, 150, 150, 100]) do
          cells.borders = []
        end
        table([["BEGINNING BALANCE", "#{price(cash_on_hand_account.balance(to_date: (to_date.beginning_of_day - 1.second)))}"]], cell_style: { size: 9, font: "Helvetica", :inline_format => true}, column_widths: [120, 150, 150, 100]) do
          cells.borders = []
        end
        table([["ADD SALES", "#{price(cash_on_hand_account.debits_balance(from_date: from_date, to_date: to_date) - employee.received_cash_transfers(from_date: Date.today, to_date: Date.today).sum(&:amount)) }"]], cell_style: { size: 9, font: "Helvetica", :inline_format => true}, column_widths: [120, 150, 150, 100]) do
          cells.borders = []
        end
        table([["LESS RETURNS AND REMITTANCES", "#{price(cash_on_hand_account.credits_balance(from_date: from_date, to_date: to_date)) }"]], cell_style: { size: 9, font: "Helvetica", :inline_format => true}, column_widths: [120, 150, 150, 100]) do
          cells.borders = []
        end
        stroke_horizontal_rule
        table([["<b>ENDING BALANCE</b>", "<b>#{price(cash_on_hand_account.balance(to_date: to_date.end_of_day))}</b>"]], cell_style: { size: 9, font: "Helvetica", :inline_format => true}, column_widths: [120, 150, 150, 100]) do
          cells.borders = []
          row(0).text_color = "008751"
        end
      end
    end
    def orders_table
      move_down 10
      table(orders_data, header: false,  cell_style: { size: 9, font: "Helvetica", :inline_format => true}) do
      end
      move_down 10
    end
    def orders_data
      if @employee.present? && !@employee.proprietor?
        [["DATE", "OR", "CUSTOMER", "ITEMS", "DISCOUNT", "TOTAL COST"]] +
        @orders_data ||= @orders.map{|o| [
          o.date.strftime("%B %e, %Y"),
          o.reference_number,
          o.commercial_document.try(:name).try(:upcase),
          order_description(o),
          price(o.discount_amount),
          o.returned_at.present? ? 'SALES RETURN' : price(o.try(:total_cost))] }
      else
         [["DATE", "OR", "CUSTOMER", "ITEMS", "COGS", "DISCOUNT", "TOTAL COST", "INCOME"]] +
        @orders_data ||= @orders.ordered_on(from_date: (@from_date.beginning_of_day), to_date: @to_date.end_of_day).map{|o| [
          o.date.strftime("%B %e, %Y"),
          o.reference_number,
          o.commercial_document.try(:name).try(:upcase),
          order_description(o),
          price(o.cost_of_goods_sold),
          price(o.discount_amount),
          o.returned_at.present? ? 'SALES RETURN' : price(o.try(:total_cost)),
          price(o.income)] }
          end
    end

  end
end

module Reports
  class CashReceiptsPdf < Prawn::Document
    attr_reader :from_date, :to_date, :cash_receipts, :employee, :view_context, :business
    def initialize(args)
      super(margin: 30, page_size: 'A4')
      @from_date     = args[:from_date]
      @to_date       = args[:to_date]
      @cash_receipts = args[:cash_receipts]
      @employee      = args[:employee]
      @business      = @employee.business
      @view_context  = args[:view_context]
      heading
      cash_on_hand_account_details
      cash_receipts_table
    end
    private
    def price(number)
      view_context.number_to_currency(number, :unit => "P ")
    end

    def heading
      bounding_box [360, 770], width: 200 do
        text "#{business.name.upcase }", style: :bold, size: 12
    end
    bounding_box [0, 770], width: 400 do
      text "CASH RECEIPTS REPORT", style: :bold, size: 12
      if from_date == to_date
        text "Date: #{from_date.strftime("%b. %e, %Y")}", size: 10
      else
        text "Date Covered: #{from_date.strftime("%b. %e, %Y")} - #{to_date.strftime("%b. %e, %Y")}", size: 10
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

        table([["CASH ACCOUNT", "#{employee.cash_on_hand_account.try(:name)}"]], cell_style: { size: 9, font: "Helvetica", :inline_format => true}, column_widths: [120, 150, 150, 100]) do
          cells.borders = []
        end
        table([["BEGINNING BALANCE", "#{price employee.cash_on_hand_account.balance(to_date: to_date.yesterday)}"]], cell_style: { size: 9, font: "Helvetica", :inline_format => true}, column_widths: [120, 150, 150, 100]) do
          cells.borders = []
        end
        table([["ADD SALES", "#{price employee.cash_on_hand_account.debits_balance(from_date: from_date, to_date: to_date)}"]], cell_style: { size: 9, font: "Helvetica", :inline_format => true}, column_widths: [120, 150, 150, 100]) do
          cells.borders = []
        end
        table([["LESS RETURNS AND REMITTANCES", "#{price employee.cash_on_hand_account.credits_balance(from_date: from_date, to_date: to_date) }"]], cell_style: { size: 9, font: "Helvetica", :inline_format => true}, column_widths: [120, 150, 150, 100]) do
          cells.borders = []
        end
        stroke_horizontal_rule
        table([["<b>ENDING BALANCE</b>", "<b>#{price employee.cash_on_hand_account.balance(to_date: to_date)}</b>"]], cell_style: { size: 9, font: "Helvetica", :inline_format => true}, column_widths: [120, 150, 150, 100]) do
          cells.borders = []
          row(0).text_color = "008751"
        end
      end
    end

    def cash_receipts_table
      move_down 10
      table(orders_data, header: false,  cell_style: { size: 9, font: "Helvetica", :inline_format => true}, column_widths: [120, 150, 150, 100]) do
      end
      move_down 10
    end
    def orders_data
        [["DATE", "CUSTOMER", "DESCRIPTION", "TOTAL COST"]] +
        @cash_receipts_data ||= cash_receipts.map{|entry|
          [entry.entry_date.strftime("%B %e, %Y"),
           entry.commercial_document.try(:name).try(:upcase),
           entry.description.gsub("₱", "P"),
           price(entry.debit_amounts.where(account: employee.cash_on_hand_account).sum(&:amount))] } +
        [["", "", "TOTAL", "#{price(cash_receipts.map{|entry| entry.debit_amounts.where(account: employee.cash_on_hand_account).sum(&:amount)}.sum)}"]]
    end

  end
end

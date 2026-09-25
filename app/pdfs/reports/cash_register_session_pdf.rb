# frozen_string_literal: true

module Reports
  # End-of-day report scoped to a single CashRegisterSession.
  # Mirrors Reports::SalesPdf but sources totals from the session
  # instead of a calendar date range.
  class CashRegisterSessionPdf < Prawn::Document
    attr_reader :cash_register_session,
      :orders,
      :credit_sales,
      :transfer_entries,
      :cash_receipts,
      :items_summary,
      :employee,
      :view_context,
      :business,
      :cash_account,
      :store_front

    def initialize(args)
      super(margin: 30, page_size: "A4")
      @cash_register_session = args.fetch(:cash_register_session)
      @orders       = args[:orders] || cash_register_session.sales_orders
      @credit_sales = args[:credit_sales] || cash_register_session.credit_sales
      @transfer_entries  = args[:transfer_entries] || cash_register_session.transfer_entries
      @cash_receipts     = args[:cash_receipts] || cash_register_session.cash_receipts
      @items_summary = args[:items_summary] || cash_register_session.items_summary
      @employee     = args[:employee] || cash_register_session.employee
      @store_front  = args[:store_front] || cash_register_session.store_front
      @cash_account = args[:cash_account] || cash_register_session.cash_account
      @business     = args[:business]
      @view_context = args[:view_context]
      heading
      session_details
      cash_summary
      items_table
      cash_receipts_table
      credit_sales_table
      transfers_table
    end

    private

    def price(number)
      @view_context.number_to_currency(number, unit: "P ")
    end

    def order_description(order)
      if order.line_items.present?
        order.line_items_name
      elsif order.description.present?
        order.description
      end
    end

    def heading
      bounding_box([360, 770], width: 200) do
        text(business.try(:name).to_s.upcase, style: :bold, size: 12)
      end
      bounding_box([0, 770], width: 400) do
        text("END OF DAY REPORT", style: :bold, size: 12)
        text("Session Date: #{cash_register_session.session_date.strftime("%b. %e, %Y")}", size: 10)
        text("Status: #{cash_register_session.status.upcase}", size: 10)
        if store_front.present?
          text("Branch: #{store_front.name}", style: :bold, size: 10)
        end
      end
      move_down(10)
      stroke_horizontal_rule
    end

    def detail_row(label, value)
      table(
        [[label, value]],
        cell_style: { size: 9, font: "Helvetica", inline_format: true },
        column_widths: [150, 385],
      ) do
        cells.borders = []
      end
    end

    def session_details
      detail_row("CASHIER ", employee.try(:full_name).to_s)
      detail_row("CASH ACCOUNT", cash_account.try(:name).to_s)
      detail_row("OPENED AT", cash_register_session.opened_at.try(:strftime, "%b %e, %Y %I:%M %p").to_s)
      if cash_register_session.closed_at.present?
        detail_row("CLOSED AT", cash_register_session.closed_at.try(:strftime, "%b %e, %Y %I:%M %p").to_s)
      end
    end

    def cash_summary
      move_down(8)
      text("CASH SUMMARY", style: :bold, size: 10)
      detail_row("BEGINNING BALANCE (SYSTEM)", price(cash_register_session.beginning_balance))
      detail_row("BEGINNING BALANCE (DECLARED)", price(cash_register_session.opening_declared_amount || 0))
      detail_row(
        "ADD: CASH RECEIPTS (#{cash_receipts.count} transactions)",
        price(cash_register_session.cash_receipts_total),
      )
      detail_row(
        "ADD: TRANSFERS IN (#{transfer_entries.count} entries)",
        price(cash_register_session.transfers_in_total),
      )
      detail_row("LESS: TRANSFERS (OUT) & REFUNDS", price(cash_register_session.cash_credits_total))
      detail_row(
        "CREDIT SALES - NOT IN DRAWER (#{credit_sales.count} sales)",
        price(cash_register_session.credit_sales_total),
      )
      detail_row("DISCOUNTS GIVEN", price(orders.to_a.sum(&:discount_amount)))
      stroke_horizontal_rule
      table(
        [["<b>ENDING BALANCE (EXPECTED)</b>", "<b>#{price(cash_register_session.expected_cash)}</b>"]],
        cell_style: { size: 9, font: "Helvetica", inline_format: true },
        column_widths: [150, 385],
      ) do
        cells.borders = []
        row(0).text_color = "008751"
      end
      if cash_register_session.closing_declared_amount.present?
        detail_row("ENDING BALANCE (COUNTED)", price(cash_register_session.closing_declared_amount))
        table(
          [["<b>VARIANCE (SHORT / OVER)</b>", "<b>#{price(cash_register_session.variance_amount || 0)}</b>"]],
          cell_style: { size: 9, font: "Helvetica", inline_format: true },
          column_widths: [150, 385],
        ) do
          cells.borders = []
        end
      end
    end

    def section_table(title, data)
      return if data.length <= 1

      move_down(10)
      text(title, style: :bold, size: 10)
      table(
        data,
        header: false,
        width: bounds.width,
        cell_style: { size: 9, font: "Helvetica", inline_format: true },
      ) do
      end
      move_down(10)
    end

    def items_table
      rows = [["ITEM", "BARCODE", "QTY", "AMOUNT"]] +
        items_summary.map { |row| [row[:name].to_s, row[:bar_code].to_s, row[:quantity].to_s, price(row[:amount])] }
      section_table("INVENTORIES SOLD", rows)
    end

    def cash_receipts_table
      rows = [["TIME", "TYPE", "CUSTOMER", "AMOUNT"]] +
        cash_receipts.map do |row|
          [
            row[:date].try(:strftime, "%I:%M %p").to_s,
            row[:kind].to_s,
            row[:customer_name].to_s,
            price(row[:amount]),
          ]
        end
      section_table("CASH RECEIPTS", rows)
    end

    def credit_sales_table
      rows = [["DATE", "OR", "CUSTOMER", "ITEMS", "TOTAL COST"]] +
        credit_sales.map do |o|
          [
            o.date.try(:strftime, "%B %e, %Y").to_s,
            o.reference_number.to_s,
            o.commercial_document.try(:name).try(:upcase).to_s,
            order_description(o).to_s,
            price(o.try(:total_cost_less_discount)),
          ]
        end
      section_table("CREDIT SALES", rows)
    end

    def transfers_table
      rows = [["DATE", "DESCRIPTION", "IN", "OUT"]] +
        transfer_entries.map do |entry|
          cash_in = entry.debit_amounts.where(account: cash_account).sum(:amount)
          cash_out = entry.credit_amounts.where(account: cash_account).sum(:amount)
          [
            entry.entry_date.try(:strftime, "%B %e, %Y %I:%M %p").to_s,
            entry.description.to_s,
            cash_in.zero? ? "" : price(cash_in),
            cash_out.zero? ? "" : price(cash_out),
          ]
        end
      section_table("TRANSFERS", rows)
    end
  end
end

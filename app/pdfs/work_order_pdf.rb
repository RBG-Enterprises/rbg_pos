# frozen_string_literal: true

class WorkOrderPdf < Prawn::Document
  def initialize(work_orders, from_date, to_date, view_context)
    super(margin: 20, page_size: "A4")
    @work_orders = work_orders
    @from_date = from_date
    @to_date = to_date
    @view_context = view_context
    heading
    work_orders_table
  end

  private

  def price(number)
    @view_context.number_to_currency(number, unit: "P ")
  end

  def heading
    text("WORK ORDERS REPORT", align: :center, style: :bold)
    if @from_date && @to_date
      move_down(5)
      text("From: #{@from_date.strftime("%B %e, %Y")} To: #{@to_date.strftime("%B %e, %Y")} ", size: 9, align: :center)
    end
    move_down(5)
    stroke do
      stroke_color("CCCCCC")
      line_width(0.2)
      stroke_horizontal_rule
      move_down(15)
    end
  end

  def work_orders_table
    table(work_orders_data, cell_style: { size: 7, inline_format: true }) do
      row(0).font_style = :bold
      column(6).align = :right
      column(7).align = :right
      column(8).align = :right

      row(0).background_color = "DDDDDD"
      row(-1).background_color = "ECF39F"
      row(-1).font_style = :bold
      row(-1).size = 8
    end
  end

  def work_orders_data
    [[
      "DATE",
      "CUSTOMER",
      "#",
      "UNIT",
      "STATUS",
      "REPORTED PROBLEM",
      "TECHNICIANS",
      "SPARE PARTS",
      "CHARGES",
      "TOTAL COST",
      "RECEIVED DATE",
      "RELEASE DATE",
      "DONE DATE",
    ]] +
      @table_data ||= @work_orders.map { |a|
        [
          a.created_at.strftime("%B %e, %Y"),
          a.customer_name,
          a.service_number,
          a.product_unit.try(:description),
          a.status.try(:titleize),
          a.reported_problem,
          a.technicians_name,
          price(a.total_spare_parts_cost),
          price(a.total_service_charges_cost),
          price(a.total_charges_cost),
          a.created_at.strftime("%B %e, %Y"),
          a.release_date.try(:strftime, "%B %e, %Y"),
          a.done_at.try(:strftime, "%B %e, %Y"),
        ]
      } +
        [[
          "",
          "",
          "",
          "",
          "",
          "",
          "#{price(@work_orders.total_spare_parts_cost(from_date: @from_date, to_date: @to_date))}",
          "#{price(@work_orders.total_service_charges_cost(from_date: @from_date, to_date: @to_date))}",
          "#{price(@work_orders.total_charges_cost(from_date: @from_date, to_date: @to_date))}",
          "",
          "",
          "",
        ]]
  end
end

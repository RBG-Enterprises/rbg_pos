require 'barby'
require 'barby/barcode/code_39'
require 'barby/outputter/png_outputter'
require 'stringio'
class ServiceFormPdf < Prawn::Document
  # Single source of truth for the two-column geometry, derived from the
  # printable area so nothing drifts off a LETTER page.
  GUTTER = 12
  LEFT_RATIO = 0.61

  def initialize(work_order, view_context)
    super(margin: 40, page_size: 'LETTER', page_layout: :portrait)
    @work_order = work_order
    @view_context = view_context
    header
    columns
  end

  private
  def price(number)
    @view_context.number_to_currency(number, :unit => "P ")
  end

  # Header lives entirely in normal flow (inside the margins): logo floated
  # at the top-left, title beside it, barcode pinned to the printable
  # top-right. Cursor is synced below whichever block runs taller.
  def header
    float do
      image(Rails.root.join("app/assets/images/rbg_logo.png"), width: 55)
    end
    indent(70) do
      text "RBG COMPUTERS, CELLSHOP AND ENTERPRISES", style: :bold, size: 12
      text "#{@work_order.store_front.name} Repair Center", size: 9
    end
    barcode_width = 150
    box = bounding_box([bounds.width - barcode_width, bounds.top], width: barcode_width) do
      text "RELEASING FORM", align: :right, size: 10, style: :bold
      move_down 4
      barcode = Barby::Code39.new(@work_order.service_number)
      image StringIO.new(barcode.to_png(height: 60, margin: 0, xdim: 2)), position: :right, height: 30
      move_down 2
      text "##{@work_order.service_number}", size: 15, align: :right
    end
    move_cursor_to([cursor, bounds.top - box.height].min)
    move_down 5
    stroke_horizontal_rule
    move_down 5
  end

  # Two columns sized from the printable width. The short money column is
  # drawn first so it stays on page 1; the details column then flows across
  # as many pages as it needs instead of dragging everything with it.
  def columns
    left_width = ((bounds.width - GUTTER) * LEFT_RATIO).round
    right_x = left_width + GUTTER
    right_width = bounds.width - right_x
    top = cursor
    bounding_box([right_x, top], width: right_width) do
      charges_details
      spare_parts_details
      summary_details
    end
    move_cursor_to(top)
    bounding_box([0, top], width: left_width) do
      customer_details
      product_details
      reported_problem
      diagnosis_details
      actions_taken_details
    end
  end

  def customer_details
    move_down 20
    text "CUSTOMER DETAILS", style: :bold, size: 11
    move_down 2
    table(customer_details_data, cell_style: { size: 9.5, font: "Helvetica", inline_format: true, :padding => [2,0,0,0]}, column_widths: [10, 140, 160]) do
        cells.borders = []
        # column(0).background_color = "CCCCCC"
    end
    move_down 5
    stroke_horizontal_rule
  end
  def customer_details_data
    @customer_details_data ||=  [["","Customer",  "#{@work_order.customer_full_name.try(:upcase)}"]] +
                                [["", "Contact Person", "#{@work_order.contact_person}"]] +
                                [["", "Address", "#{@work_order.customer_address}"]] +
                                [["", "Contact Number",  "#{@work_order.customer_contact_number}"]]
  end
  def product_details
    move_down 5
    text "PRODUCT DETAILS", style: :bold, size: 11
    table(product_details_data, cell_style: { size: 9.5, font: "Helvetica", inline_format: true, :padding => [3,0,0,0]}, column_widths: [10, 140, 160]) do
        cells.borders = []
        # column(0).background_color = "CCCCCC"
    end
    move_down 5
    stroke_horizontal_rule
    move_down 5
  end
  def product_details_data
    @product_details_data ||=  [["", "Date Released",  "#{@work_order.release_date.try(:strftime,("%B %e, %Y"))}"]] +
                                [["", "Description",  "#{@work_order.description}"]] +
                                [["", "Model Number", "#{@work_order.model_number.try(:upcase)}"]] +
                                [["", "Serial Number", "#{@work_order.serial_number.try(:upcase)}"]] +
                                [["", "Physical Condition", "#{@work_order.physical_condition}"]] +
                                [["", "<b>ACCESSORIES</b>"]] +
                                @work_order.accessories.map{|a| ["","", "#{a.quantity.to_i} - #{a.description} <i>(#{a.serial_number})</i>"] }
  end
  def reported_problem
    text "REPORTED PROBLEM", style: :bold, size: 11
    table(reported_problem_data, cell_style: { size: 9.5, font: "Helvetica", inline_format: true, :padding => [3,0,0,0]}, column_widths: [10, 140, 160]) do
        cells.borders = []
        # column(0).background_color = "CCCCCC"
    end
    move_down 5
    stroke_horizontal_rule
    move_down 5
  end

  def reported_problem_data
    @reported_problem_data ||= [["", "", "#{@work_order.reported_problem}"]] +
    [["",  "<b>TECHNICIANS</b>" ]] +
    @work_order.technicians.map{ |a| ["", "", a.full_name] }
  end

  def diagnosis_details
    move_down 5
    text "DIAGNOSIS", style: :bold, size: 11
    if @work_order.diagnoses.present?
      table(diagnosis_details_data, cell_style: { size: 9.5, font: "Helvetica", inline_format: true, :padding => [3,0,0,0]}, column_widths: [10, 140,  160]) do
          cells.borders = []
          column(0).size = 9
          # column(0).background_color = "CCCCCC"
      end
    else
      text "No Diagnosis Yet", size: 9.5
    end
    move_down 5
    stroke_horizontal_rule
  end
  def diagnosis_details_data
    @diagnosis_details_data ||= @work_order.diagnoses.map{|a| ["", a.created_at.strftime("%b %e, %l:%M %p"),  a.content]}
  end
  def actions_taken_details
    move_down 5
    text "ACTIONS TAKEN", style: :bold, size: 11
    if @work_order.actions_taken.present?
      table(actions_taken_details_data, cell_style: { size: 9.5, font: "Helvetica", inline_format: true, :padding => [3,0,0,0]}, column_widths: [10, 140,  160]) do
          cells.borders = []
          column(0).size = 9
          # column(0).background_color = "CCCCCC"
      end
    else
      text "No Actions Taken Yet", size: 9.5
    end
    move_down 5
    stroke_horizontal_rule

  end
  def actions_taken_details_data
    @actions_taken_details_data ||= @work_order.actions_taken.map{|a| ["", "#{a.created_at.strftime("%b %e, %l:%M %p")}",  "#{a.content} -  #{a.user.try(:full_name)}"]}
  end
  def charges_details
    move_down 15
    text "SERVICE CHARGES", style: :bold, size: 10
    if @work_order.service_charges.present?
      table(charge_details_data, cell_style: { size: 9.5, font: "Helvetica", inline_format: true, :padding => [3,0,0,0]}, column_widths: [10, 120, 50]) do
          cells.borders = []
          column(2).align = :right

          # column(0).background_color = "CCCCCC"
      end
    end
    move_down 10
  end
  def charge_details_data
    @charge_details_data ||= @work_order.service_charges.map{|a| ["", a.description, price(a.amount)] } +
    [["", "SUBTOTAL", "<b>#{price(@work_order.service_charges.sum(:amount))}</b>"]]
  end
  def spare_parts_details
    text "SPARE PARTS", style: :bold, size: 10
    if @work_order.sales_order_line_items.present?
      table(spare_part_details_data, cell_style: { size: 9.5, font: "Helvetica", inline_format: true, :padding => [3,0,0,0]}, column_widths: [10, 120, 50]) do
          cells.borders = []
          column(2).align = :right
          # column(0).background_color = "CCCCCC"
      end
    end
    move_down 10
end
  def spare_part_details_data
    @spare_part_details_data ||= @work_order.sales_order_line_items.map{|a| ["", a.product_name, price(a.total_cost)] } +
    [["", "SUBTOTAL", "<b>#{price(@work_order.sales_order_line_items.sum(:total_cost))}</b>"]]
  end

  def summary_details
    move_down 10
    text "SUMMARY", style: :bold, size: 10
    move_down 5
      table(payment_data, cell_style: { size: 9.5, font: "Helvetica", inline_format: true, :padding => [5,0,0,0]}, column_widths: [10, 120, 50]) do
          cells.borders = []
          column(2).align = :right

    end
  end
  def payment_data
    @payment_date ||= [["", "RECEIVABLES", "#{price(@work_order.accounts_receivable_less_sales_returns_total)}"]] +
                      [["", "PAYMENTS", "#{price(@work_order.cash_payments_total)}"]] +
                      [["", "BALANCE", "#{price(@work_order.balance_total)}"]]
  end
end

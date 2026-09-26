# frozen_string_literal: true

require "barby"
require "barby/barcode/code_39"
require "barby/outputter/prawn_outputter"

class ServiceTagPdf < Prawn::Document
  BRANCHES = [
    ["LAGAWE", "0916-8762-834 / 0935-603-8798", "Computer/Cellphone Repair"],
    ["LAMUT", "0945-284-8276", "Computer/Cellphone Repair"],
    ["ALFONSO LISTA", "0956-246-5678", "Computer/Cellphone Repair"],
    ["MADDELA", "0975-065-4130", "Computer/Cellphone Repair"],
  ]

  def initialize(work_order, view_context)
    super(margin: 20, page_size: "A5", page_layout: :landscape)
    @work_order = work_order
    @view_context = view_context
    @page_width = bounds.width

    header_section
    move_down(5)
    claim_note
    move_down(5)
    stroke_horizontal_rule
    move_down(6)
    form_grid
    move_down(6)
    item_problem_and_serials
    signature_section
  end

  private

  def price(number)
    @view_context.number_to_currency(number, unit: "P ")
  end

  def top_y
    @top_y ||= cursor
  end

  def header_section
    company_details_box
    job_order_box
    move_cursor_to(top_y - 68)
  end

  def company_details_box
    job_box_width = 130
    bounding_box([0, top_y], width: @page_width - job_box_width - 10) do
      image(Rails.root.join("app/assets/images/rbg_logo.png"), at: [0, 0], width: 34)
      table(
        [["", "RBG COMPUTERS, CELLSHOP AND ENTERPRISES"]],
        cell_style: { font: "Helvetica", padding: [0, 0, 1, 0] },
        column_widths: [50],
      ) do
        cells.borders = []
        column(1).size = 11
        column(1).font_style = :bold
      end
      table(
        [["", "#{@work_order.store_front.name} Repair Center"]],
        cell_style: { font: "Helvetica", padding: [0, 0, 0, 0] },
        column_widths: [50],
      ) do
        cells.borders = []
        column(1).size = 8
      end
      move_down(14)
      BRANCHES.each_slice(2) do |slice|
        line = slice.map { |name, phone, _| "#{name}: #{phone}" }.join("     ")
        text(line, size: 6, style: :bold)
        move_down(1)
      end
    end
  end

  def job_order_box
    job_box_width = 130
    bounding_box([@page_width - job_box_width, top_y], width: job_box_width, height: 55) do
      stroke_bounds
      move_down(6)
      text("CLAIM #", align: :center, size: 8, style: :bold, color: "666666")
      move_down(3)
      text(@work_order.service_number.to_s, align: :center, size: 18, style: :bold, color: "CC0000")
    end
  end

  def claim_note
    text(
      "* Please DO NOT FORGET to present this CLAIM FORM when claiming your unit.",
      size: 7,
      style: :italic,
    )
  end

  def form_grid
    grid_top = cursor
    half_width = @page_width / 2.0
    right_cell_style = { size: 8, font: "Helvetica", inline_format: true, padding: [2, 3, 2, 3] }

    left_table = make_table(
      left_column_data,
      cell_style: { size: 8, font: "Helvetica", inline_format: true, padding: [2, 3, 2, 3] },
      column_widths: [78, half_width - 78],
    )

    natural_right_table = make_table(
      right_column_data,
      cell_style: right_cell_style,
      column_widths: [82, half_width - 82],
    )
    extra_height = [left_table.height - natural_right_table.height, 0].max

    right_table = make_table(
      right_column_data,
      cell_style: right_cell_style,
      column_widths: [82, half_width - 82],
    ) do |table|
      table.row(@warranty_status_row).column(1).font_style = :bold
      table.row(@warranty_status_row).column(1).text_color = @work_order.under_warranty? ? "1F7A1F" : "CC0000"
      table.row(1).each { |cell| cell.padding_bottom += extra_height } if extra_height.positive?
    end

    bounding_box([0, grid_top], width: half_width) { left_table.draw }
    bounding_box([half_width, grid_top], width: half_width) { right_table.draw }

    move_cursor_to(grid_top - [left_table.height, right_table.height].max)
  end

  def left_column_data
    [
      ["Received Date:", @work_order.date_received.try(:strftime, "%B %e, %Y")],
      ["Received Time:", @work_order.time_received.try(:strftime, "%I:%M %p")],
      ["Client Name:", "<b>#{@work_order.customer_full_name.try(:upcase)}</b>"],
      ["Contact Person:", @work_order.contact_person],
      ["Department:", @work_order.department.try(:customer_name_and_department)],
      ["Address:", @work_order.customer_address],
      ["Contact #:", @work_order.customer_contact_number],
      ["Downpayment:", "<b>#{price(@work_order.payments_total.try(:abs))}</b>"],
    ]
  end

  def right_column_data
    data = [
      ["Item Description:", @work_order.description],
      ["Item Accessories:", accessories_text],
    ]
    @warranty_status_row = data.length
    data << ["Warranty Status:", @work_order.under_warranty? ? "UNDER WARRANTY" : ""]
    data << ["Supplier:", @work_order.supplier.try(:business_name)]
    data << ["Purchase Date:", @work_order.purchase_date.try(:strftime, "%B %e, %Y")]
    data << ["Warranty Expiry:", @work_order.expiry_date.try(:strftime, "%B %e, %Y")]
    data
  end

  def accessories_text
    return "N/A" if @work_order.accessories.blank?

    @work_order.accessories.map { |a| "#{a.quantity.to_i} - #{a.description} (#{a.serial_number})" }.join("\n")
  end

  def item_problem_and_serials
    table(
      [
        ["ITEM PROBLEM", "SERIAL #"],
        [@work_order.reported_problem, @work_order.serial_number],
      ],
      cell_style: { size: 8, font: "Helvetica", padding: [3, 4, 3, 4] },
      column_widths: [@page_width / 2.0, @page_width / 2.0],
    ) do
      row(0).font_style = :bold
      row(0).size = 7
      row(0).background_color = "EEEEEE"
    end
  end

  def signature_section
    move_down(18)
    col_width = @page_width / 4.0

    cell_style = { borders: [], size: 8, style: :bold, align: :center, valign: :bottom, height: 16 }
    table(
      [[@work_order.customer_full_name.to_s.upcase, technician_in_charge_name, "", ""]],
      column_widths: [col_width] * 4,
      cell_style: cell_style.merge(padding: [2, 3, 2, 3]),
    )

    move_down(30)
    y = cursor
    render_signature(12, y, col_width - 24)
    4.times do |i|
      x1 = (i * col_width) + 12
      x2 = ((i + 1) * col_width) - 12
      stroke_line([x1, y], [x2, y])
    end

    move_down(2)
    table(
      [["Client Name", "Technician In Charge", "Released To", "Released Date"]],
      column_widths: [col_width] * 4,
      cell_style: { borders: [], size: 8, align: :center },
    )
  end

  def technician_in_charge_name
    @work_order.technician.try(:full_name).to_s.upcase
  end

  def render_signature(x, y, width)
    return unless @work_order.signature.attached?

    height = 28
    io = StringIO.new(@work_order.signature.download)
    image(io, at: [x, y + height], width: width, height: height)
  rescue StandardError
    nil
  end
end

require 'barby'
require 'barby/barcode/code_39'
require 'barby/outputter/prawn_outputter'
class ServiceTagPdf < Prawn::Document
  def initialize(work_order, view_context)
    super(margin: 40, page_size: 'A4')
    @work_order = work_order
    @view_context = view_context
    bounding_box [300, 770], width: 220 do
      contact_details
    end
    bounding_box [0, 770], width: 250 do
      logo_details
      heading
      customer_details
      product_details
      if @work_order.under_warranty?
        warranty_details
      end
      reported_problem
    end
  end

  private

  def price(number)
    @view_context.number_to_currency(number, :unit => "P ")
  end

  def logo_details
    image(Rails.root.join("app/assets/images/rbg_logo.png"), at: [0,0], width: 60)
  end

  def contact_details
    text "SERVICE #: #{@work_order.service_number}", size: 16, style: :bold
    move_down 10
      text "LAGAWE REPAIR CENTER", size: 10, style: :bold
      move_down 2
      table([["0916-8762-834", "0935-603-8798"]],cell_style: {font: "Helvetica", :padding => [3,0,0,0]}, column_widths: [100, 100]) do
        cells.borders = []
        row(0).font_style = :bold
      end
      table([["COMPUTER REPAIR", "CELLPHONE REPAIR"]],cell_style: {size: 8, font: "Helvetica", :padding => [0,0,0,0]}, column_widths: [100, 100]) do
        cells.borders = []
      end
      move_down 10
      stroke_horizontal_rule
      move_down 10
      text "LAMUT REPAIR CENTER", size: 10, style: :bold
      move_down 2
      table([["0945-284-8276"]],cell_style: {font: "Helvetica", :padding => [3,0,0,0]}, column_widths: [150, 100]) do
        cells.borders = []
        row(0).font_style = :bold
      end
      table([["COMPUTER/CELLPHONE REPAIR"]],cell_style: {size: 8, font: "Helvetica", :padding => [0,0,0,0]}, column_widths: [150, 100]) do
        cells.borders = []
      end
      move_down 10
      stroke_horizontal_rule
      move_down 10
    
      text "ALFONSO LISTA REPAIR CENTER", size: 10, style: :bold
      move_down 2
      table([["0956-246-5678"]],cell_style: {font: "Helvetica", :padding => [3,0,0,0]}, column_widths: [150, 100]) do
        cells.borders = []
        row(0).font_style = :bold
      end
      table([["COMPUTER/CELLPHONE REPAIR"]],cell_style: {size: 8, font: "Helvetica", :padding => [0,0,0,0]}, column_widths: [150, 100]) do
        cells.borders = []
      end

      move_down 10
      stroke_horizontal_rule
      move_down 10
    
      text "MADDELA REPAIR CENTER", size: 10, style: :bold
      move_down 2
      table([["0975-225-2790"]],cell_style: {font: "Helvetica", :padding => [3,0,0,0]}, column_widths: [150, 100]) do
        cells.borders = []
        row(0).font_style = :bold
      end
      table([["COMPUTER/CELLPHONE REPAIR"]],cell_style: {size: 8, font: "Helvetica", :padding => [0,0,0,0]}, column_widths: [150, 100]) do
        cells.borders = []
      end
  end

  def heading
      table([["", "RBG COMPUTERS, CELLSHOP AND ENTERPRISES"]], cell_style: { font: "Helvetica", :padding => [0,0,0,0]}, column_widths: [70]) do
        cells.borders = []
        column(2).size = 14


        column(1).font_style = :bold
      end
      table([["", "#{@work_order.store_front.name} Repair Center"]], cell_style: { font: "Helvetica", :padding => [0,0,0,0]}, column_widths: [70]) do
        cells.borders = []
        column(1).size = 10
      end
      move_down 30
      table([["* Please DO NOT FORGET to present this CLAIM FORM when claiming your unit."]], cell_style: { size: 9, font: "Helvetica"}, column_widths: [250]) do
      end

      # text "RBG", style: :bold, size: 37
      #
      # text "COMPUTERS, CELLSHOP AND ENTERPRISES", style: :bold, size: 14
      #
      #
      # text "<u>SERVICE #: #{@work_order.service_number}</u>", size: 12, style: :bold, inline_format: true

  end

  def customer_details
      move_down 10
      text "CUSTOMER DETAILS", style: :bold, size: 10
      move_down 2
      table(customer_details_data, cell_style: { size: 10, font: "Helvetica", inline_format: true, :padding => [2,0,0,0]}, column_widths: [20, 110, 100]) do
          cells.borders = []
          # column(0).background_color = "CCCCCC"
      end
      move_down 5
      stroke_horizontal_rule


  end
  def customer_details_data
    @customer_details_data ||=  [["","Customer:",  "<b>#{@work_order.customer_full_name.try(:upcase)}</b>"]] +
                                [["", "Contact Person:", "#{@work_order.contact_person}"]] +
                                [["", "Department:", "#{@work_order.department.try(:customer_name_and_department)}"]] +
                                [["", "Address:", "#{@work_order.customer_address}"]] +
                                [["", "Contact #:",  "#{@work_order.customer_contact_number}"]] +
                                [["", "DOWNPAYMENT:",  "<b>#{price(@work_order.payments_total.try(:abs))}</b>"]]

  end
  def product_details
    move_down 5
    text "PRODUCT DETAILS", style: :bold, size: 10
    table(product_details_data, cell_style: { size: 11, font: "Helvetica", inline_format: true, :padding => [3,0,0,0]}, column_widths: [20, 110, 100]) do
        cells.borders = []
        # column(0).background_color = "CCCCCC"
    end
    move_down 5
    stroke_horizontal_rule
    move_down 5
  end
  def product_details_data
    @product_details_data ||=   [["", "Date Received:",  "#{@work_order.created_at.strftime("%B %e, %Y")}"]] +
                                [["", "Description:",  "#{@work_order.description}"]] +
                                [["", "Model Number:", "#{@work_order.model_number.try(:upcase)}"]] +
                                [["", "Serial Number:", "#{@work_order.serial_number.try(:upcase)}"]] +
                                [["", "Physical Condition:", "#{@work_order.physical_condition}"]] +
                                [["", "<b>ACCESSORIES</b>"]] +
                                @work_order.accessories.map{|a| ["","", "#{a.quantity.to_i} - #{a.description} <i>(#{a.serial_number})</i>"] }
  end
  def warranty_details
    text "WARRANTY DETAILS", style: :bold, size: 10
    table(warranty_details_data, cell_style: { size: 11, font: "Helvetica", inline_format: true, :padding => [3,0,0,0]}, column_widths: [20, 110, 100]) do
        cells.borders = []
        # column(0).background_color = "CCCCCC"
    end
    move_down 5
    stroke_horizontal_rule
    move_down 5
  end
  def warranty_details_data
    @warranty_details_data ||= [["", "Supplier:", "#{@work_order.supplier.try(:business_name)}"]] +
                               [["", "Purchase Date:", "#{@work_order.purchase_date.strftime("%B %e, %Y")}"]] +
                               [["", "Warranty Expiry Date:", "#{@work_order.expiry_date.strftime("%B %e, %Y")}"]]
  end

  def reported_problem
    text "REPORTED PROBLEM", style: :bold, size: 10
    table(reported_problem_data, cell_style: { size: 11, font: "Helvetica", inline_format: true, :padding => [3,0,0,0]}, column_widths: [20, 200]) do
        cells.borders = []
        # column(0).background_color = "CCCCCC"
    end
    move_down 5
  end
  def reported_problem_data
    @reported_problem_data ||= [["", "#{@work_order.reported_problem}"]]
  end
end

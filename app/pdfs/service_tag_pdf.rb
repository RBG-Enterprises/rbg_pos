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
      table([["0917-100-0659"]],cell_style: {font: "Helvetica", :padding => [3,0,0,0]}, column_widths: [150, 100]) do
        cells.borders = []
        row(0).font_style = :bold
      end
      table([["COMPUTER/CELLPHONE REPAIR"]],cell_style: {size: 8, font: "Helvetica", :padding => [0,0,0,0]}, column_widths: [150, 100]) do
        cells.borders = []
      end
      move_down 10
      stroke_horizontal_rule
      move_down 10
      text "BAMBANG REPAIR CENTER", size: 10, style: :bold
      move_down 2
      table([["0917-504-3789"]],cell_style: {font: "Helvetica", :padding => [3,0,0,0]}, column_widths: [150, 100]) do
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
  end

  def heading
      table([["RBG", "COMPUTERS, CELLSHOP AND ENTERPRISES"]], cell_style: { font: "Helvetica", :padding => [0,0,0,0]}, column_widths: [80]) do
        cells.borders = []
        column(0).size = 33
        column(0).font_style = :bold
        column(1).font_style = :bold

      end
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
  def tech_support
    text '**************************************************************************************************************'
    move_down 5
    text "SUBSCRIBE TO RBG TOTAL TECH SUPPORT", size: 14, style: :bold
    text 'Your busy. We get it. With RBG TOTAL TECH SUPPORT, we maintain your computers and printers,
    making sure they function properly, so that you can do your work without distractions.', size: 10
    move_down 10
  end
  def problem_statement
    text 'YOUR PROBLEM', size: 12, style: :bold
    move_down 5
    text 'Your work depends on your computers and
printers. When it is not maintained
properly, they hang up, slows down and breaks down.', size: 10
move_down 10

text 'When your IT equipment is not functioning
properly, they delay your work, adding
stress, and distraction to your office.', size: 10
move_down 10

text 'Hiring an IT employee to maintain your IT
equipment is costly.', size: 10
move_down 10
text 'Carrying your computers to the repair
centers takes your precious time, even
damaging it due to improper handling.', size: 10
move_down 20
text 'DO YOUR WORK WITHOUT DISTRACTIONS.', size: 16
  end
  def solution_statement
    text 'THE SOLUTION', size: 12, style: :bold
    text "When you SUBSCRIBE, we will:", size: 10
    move_down 5
    text 'MAINTAIN', size: 10, style: :bold
    text 'We will do preventive maintenance,
making sure your computers and
printers are functioning properly.', size: 10
move_down 5
text 'PROTECT', size: 10, style: :bold
text 'We will install licensed antivirus and
update it regularly protecting your precious
files and software from viruses.', size: 10
move_down 5
text 'SUPPORT', size: 10, style: :bold
text 'With years of experience, we know what it
takes to provide great IT support. We will
send out technicians to your office and fix
your IT problems as quick as possible.', size: 10
move_down 10
text 'INQUIRE NOW:', size: 10, style: :bold
move_down 10
text '0927-7365-057', style: :bold
move_down 3
text 'RONALD B. GODOY', style: :bold, size: 10
text 'Manager', size: 10
  end
end

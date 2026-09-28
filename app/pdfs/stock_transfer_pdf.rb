class StockTransferPdf < Prawn::Document 
  def initialize(stock_transfer, view_context)
      super(margin: 30, page_size: 'LETTER', page_layout: :portrait)
    @stock_transfer = stock_transfer 
    @view_context = view_context
    heading
    customer
    line_items
  end 
  
  private
  def price(number)
    @view_context.number_to_currency(number, :unit => "P ")
  end
  def unit_cost_detail(unit_cost)
    if unit_cost > 0
      price(unit_cost)
    else
      "FREE"
    end
  end
  def heading 
    text "Stock Transfer Details", align: :center
    move_down 5
    stroke_horizontal_rule
    move_down 10
  end
  def customer 
    text "Destination Branch:    #{@stock_transfer.destination_branch.try(:name)}"
    text "Date:                          #{@stock_transfer.date.strftime("%B %e, %Y")}"
    text "Number of Items:       #{@stock_transfer.line_items.count}"
   
    move_down 5
    # text "Total Cost:                  #{price(@stock_transfer.total_cost)}"
    # text "Discount:                    #{price(@stock_transfer.discount_amount)}"
    # text "Total Cost Less Discount                   #{price(@stock_transfer.total_cost_less_discount)}"
  end
  def line_items
      move_down 10 
        table line_items_data,  
      cell_style: { size: 11,  inline_format: true  }, column_widths: [170, 80, 80, 100, 100] do
        row(0).font_style = :bold
        column(3).align = :right
        column(4).align = :right
      end
    end

    def line_items_data 
      [["PRODUCT", "BARCODE", "QUANTITY", "UNIT COST", "TOTAL COST"]] +
      @line_items_data ||= @stock_transfer.line_items.map{|e| [e.stock.try(:name), e.stock.try(:barcode), e.quantity,unit_cost_detail(e.unit_cost), price(e.total_cost)] } +
      [["TOTAL", "", "", "", "#{price(@stock_transfer.line_items.total_cost)}"]]
    end

end 
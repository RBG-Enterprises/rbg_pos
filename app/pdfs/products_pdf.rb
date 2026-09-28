class ProductsPdf < Prawn::Document 
  def initialize(products, view_context)
      super(margin: 30, page_size: 'LETTER', page_layout: :portrait)
    @products = products 
    @view_context = view_context
    heading
    products_table
  end 
  
  private
  def price(number)
    @view_context.number_to_currency(number, :unit => "P ")
  end
  def heading 
    text "INVENTORY REPORT", align: :center
    text "As of: #{Time.zone.now.strftime("%B %e, %Y")}"
    move_down 5
    stroke_horizontal_rule
    move_down 10
  end
  def products_table
      move_down 10 
        table products_data,  
      cell_style: { size: 11,  inline_format: true  }, column_widths: [230, 100, 100, 100] do
        row(0).font_style = :bold
        row(0).background_color = "DDDDDD"
        row(0).size = 10
        column(3).align = :right
        column(4).align = :right
      end
    end

    def products_data
      [["PRODUCT", "DELIVERIES", "SOLD", "IN STOCK"]] +
      @products_data ||= @products.map{|e| [e.name, e.delivered_items_count, e.sold_items_count, e.in_stock] }
    end
end 
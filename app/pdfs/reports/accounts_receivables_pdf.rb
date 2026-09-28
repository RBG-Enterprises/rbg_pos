module Reports
  class AccountsReceivablesPdf < Prawn::Document 
    def initialize(customers, view_context)
      super(margin: 50, page_size: 'LETTER', page_layout: :portrait)
      @customers = customers
      @view_context = view_context
      heading
      customers_table
    end 
    private 
    def price(number)
      @view_context.number_to_currency(number, :unit => "P ")
    end
    def heading
      text 'ACCOUNTS RECEIVABLES REPORT', align: :center, style: :bold
      move_down 5
      stroke_horizontal_rule
    end 
    def customers_table
      move_down 10 
        table(customers_data, header: false,  cell_style: { size: 9, font: "Helvetica", :inline_format => true}, column_widths: [150, 200, 100]) do
           row(0).font_style = :bold
           row(0).background_color = "DDDDDD"
           row(0).size = 10
      end
    end
    def customers_data 
      [["DATE", "CUSTOMER", "AMOUNT"]] +
      @customers_data ||= @customers.map{|c| [c.last_updated_at.strftime("%B %e, %Y"), c.full_name, price(c.balance_total)]}
    end
  end 
end
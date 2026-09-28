class IncomeStatementPdf < Prawn::Document
  def initialize(revenues, expenses, employee, from_date, to_date, view_context)
    super(margin: 40, page_size: "LETTER", page_layout: :portrait)
    @revenues = revenues
    @expenses = expenses
    @employee = employee
    @from_date = from_date
    @to_date = to_date
    @view_context = view_context
    heading
    show_revenues
    show_expenses
    net_surplus
  end
  private
  def price(number)
    @view_context.number_to_currency(number, :unit => "P ")
  end
  def heading
    bounding_box [300, 760], width: 50 do
      # image "#{Rails.root}/app/assets/images/logo_kcmdc.jpg", width: 40, height: 40
    end
    bounding_box [350, 760], width: 150 do
        text "RBG", style: :bold, size: 22
        text "Poblacion East, Lagawe, Ifugao", size: 10
    end
    bounding_box [0, 760], width: 400 do
      text "Income Statement", style: :bold, size: 14
      move_down 5
      text "#{@from_date.strftime("%B %e, %Y")} - #{@to_date.strftime("%B %e, %Y")} ", size: 10
      move_down 5
    end
    move_down 10
    stroke do
      stroke_color 'CCCCCC'
      line_width 0.2
      stroke_horizontal_rule
      move_down 15
    end
  end
  def show_revenues
    text "REVENUES", style: :bold
    table(revenues_data, cell_style: { inline_format: true, size: 11, font: "Helvetica", :padding => [2,5,2,5]}, column_widths: [300, 100]) do
      cells.borders =[]
      column(1).align = :right
      row(-1).font_style = :bold
    end
     stroke do
          stroke_color 'CCCCCC'
          line_width 0.2
          stroke_horizontal_rule
          move_down 15
        end
  end
  def revenues_data
    [["", ""]] +
    @revenues_data ||= @revenues.map{|a| [a.name, price(a.balance(to_date: @to_date))] } +
    [["TOTAL REVENUES", "#{price(AccountingModule::Revenue.balance(to_date: @to_date))}"]]
  end
  def show_expenses
    text "Expenses", style: :bold
    table(expenses_data, cell_style: { inline_format: true, size: 11, font: "Helvetica", :padding => [2,5,2,5]}, column_widths: [300, 100]) do
      cells.borders =[]
      column(1).align = :right
      row(-1).font_style = :bold
    end
  end
  def expenses_data
    [["", ""]] +
    @expenses_data ||= @expenses.map{|a| [a.name, price(a.balance(to_date: @to_date))] } +
    [["TOTAL EXPENSES", "#{price(AccountingModule::Expense.balance)}"]]

  end
  def net_surplus
     stroke do
          stroke_color 'CCCCCC'
          line_width 0.2
          stroke_horizontal_rule
          move_down 15
        end
        table([["NET SURPLUS", "#{price(AccountingModule::Revenue.balance(to_date: @to_date) - AccountingModule::Expense.balance(to_date: @to_date))}"]], cell_style: { inline_format: true, size: 11, font: "Helvetica", :padding => [2,5,2,5]}, column_widths: [300, 100]) do
          row(0).font_style = :bold
          cells.borders = []
          column(1).align =:right
        end
      end

end


class IncomeStatementController < AuthenticatedController
  def index
    @from_date = params[:from_date] ? DateTime.parse(params[:from_date]) : DateTime.now.at_beginning_of_month
    @to_date = params[:to_date] ? DateTime.parse(params[:to_date]) : DateTime.now
    @revenues = AccountingModule::Revenue.all
    @expenses = AccountingModule::Expense.all
    @employee = current_user

    respond_to do |format|
      format.pdf do
        pdf = IncomeStatementPdf.new(@revenues, @expenses, @employee, @from_date, @to_date, view_context)
        send_data pdf.render, type: "application/pdf", disposition: 'inline', file_name: "Income Statement.pdf"
      end
    end
  end
end


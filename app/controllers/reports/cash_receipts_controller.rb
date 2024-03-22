module Reports
  class CashReceiptsController < AuthenticatedController
    def index
      @from_date = Chronic.parse(params[:from_date].to_date)
      @to_date   = Chronic.parse(params[:to_date].to_date)
      @user      = User.find_by(id: params[:user_id])

      if @user.present?
        @cash_receipts = @user.cash_on_hand_account.debit_entries.entered_on(from_date: @from_date, to_date: @to_date)
      else
        @cash_receipts = AccountingModule::Account.cash_on_hand_accounts.entered_on(from_date: @from_date, to_date: @to_date)
      end

      respond_to do |format|
        format.pdf do
          pdf = Reports::CashReceiptsPdf.new(
            from_date:     @from_date,
            to_date:       @to_date,
            cash_receipts: @cash_receipts,
            employee:      @user,
            view_context:  view_context)
          send_data pdf.render, type: 'application/pdf', disposition: 'inline', file_name: 'Cash Receipts Report.pdf'
          pdf = nil
        end
      end
    end
  end
end

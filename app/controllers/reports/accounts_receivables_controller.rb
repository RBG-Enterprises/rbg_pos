module Reports
  class AccountsReceivablesController < AuthenticatedController
    def index
      @customers = Customer.with_credits.sort
      respond_to do |format|
        format.pdf do
          pdf = Reports::AccountsReceivablesPdf.new(@customers, view_context)
          send_data pdf.render, type: 'application/pdf', disposition: 'inline', file_name: 'AR Report.pdf'
         pdf = nil
        end
      end
    end
  end
end

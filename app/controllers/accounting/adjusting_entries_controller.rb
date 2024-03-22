module Accounting
  class AdjustingEntriesController < AuthenticatedController
    def create
      @adjusting_entry = Accounting::AdjustingEntry.new(entry_params)
      if @adjusting_entry.valid?
        @adjusting_entry.process!
        redirect_to accounting_index_url, notice: "Entry saved successfully."
      else
        redirect_to new_accounting_entry_line_item_url, notice: 'error'
      end
    end

    private
    def entry_params
      params.require(:accounting_adjusting_entry).
      permit(:entry_date, :description, :reference_number, :employee_id, :account_number)
    end
  end
end

module Accounting
  class EntryLineItemsController < AuthenticatedController
    def new
      @entry_line_item = Accounting::EntryLineItem.new
      @adjusting_entry = Accounting::AdjustingEntry.new
    end
    def create
      @entry_line_item = Accounting::EntryLineItem.new(line_item_params)
      if @entry_line_item.valid?
        @entry_line_item.process!
        redirect_to new_accounting_entry_line_item_path, notice: 'added successfully'
      else
        render :new
      end
    end

    private
    def line_item_params
      params.require(:accounting_entry_line_item).
      permit(:amount, :account_id, :amount_type, :employee_id)
    end
  end
end

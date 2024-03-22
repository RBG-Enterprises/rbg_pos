module Accounting
	class EntriesController < AuthenticatedController
    def index
      @entries = AccountingModule::Entry.all
    end
    def new
      @entry_line_item = Accounting::EntryLineItem.new
    end
		def show
			@entry = AccountingModule::Entry.find(params[:id])
		end
	end
end

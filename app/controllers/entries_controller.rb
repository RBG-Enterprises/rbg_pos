class EntriesController < AuthenticatedController
  def destroy
    @entry = AccountingModule::Entry.find(params[:id])
    @entry.destroy
    redirect_to customers_url, notice: "Entry deleted successfully"
  end
end

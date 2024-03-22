class ChargeInvoicesController < AuthenticatedController
  def index
    if params[:search].present?
      @charge_invoices = Invoices::ChargeInvoice.text_search(params[:search]).paginate(page: params[:page], per_page: 35)
    else
      @charge_invoices = Invoices::ChargeInvoice.all.paginate(page: params[:page], per_page: 35)
    end
  end
  def edit
    @charge_invoice = Invoices::ChargeInvoice.find(params[:id])
  end
  def update
    @charge_invoice = Invoices::ChargeInvoice.find(params[:id])
    @charge_invoice.update(charge_invoice_params)
    if @charge_invoice.valid?
      @charge_invoice.save
      redirect_to computer_repair_section_work_order_url(@charge_invoice.invoiceable), notice: "Charge Invoice updated successfully."
    else
      render :edit
    end
  end
  private
  def charge_invoice_params
    params.require(:invoices_charge_invoice).permit(:number)
  end
end

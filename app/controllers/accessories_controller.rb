class AccessoriesController < AuthenticatedController
  def new
    @product_unit = ProductUnit.find(params[:product_unit_id])
    @work_order = WorkOrder.find(params[:work_order_id])
    @accessory = @product_unit.accessories.build
  end
  def create
    @product_unit = ProductUnit.find(params[:product_unit_id])
    @accessory = @product_unit.accessories.build(accessory_params)
    if @accessory.save
      redirect_to computer_repair_section_work_order_path(@accessory.work_order), notice: "Accessory added successfully"
    else
      render :new
    end
  end
  def destroy
    @accessory = Accessory.find(params[:id])
    @accessory.destroy
    redirect_to computer_repair_section_work_order_url(@accessory.work_order), notice: "Accessory removed successfully"
  end
  private
  def accessory_params
    params.require(:accessory).permit(:work_order_id, :serial_number, :description, :quantity)
  end
end

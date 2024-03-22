class UnitOfMeasurementsController < AuthenticatedController
  def new
    @product = Product.find(params[:product_id])
    @unit = StoreFrontModule::UnitOfMeasurementRegistration.new
  end

  def create
    @product = Product.find(params[:product_id])
    @unit = StoreFrontModule::UnitOfMeasurementRegistration.new(unit_params)
    if @unit.valid?
      @unit.register!
      redirect_to product_url(@product), notice: "Unit of measurement added successfully"
    else
      render :new
    end
  end

  private
  def unit_params
    params.require(:store_front_module_unit_of_measurement_registration).
    permit(:unit_code,
          :quantity,
          :description,
          :base_measurement,
          :conversion_quantity,
          :product_id,
          :selling_price)
  end
end

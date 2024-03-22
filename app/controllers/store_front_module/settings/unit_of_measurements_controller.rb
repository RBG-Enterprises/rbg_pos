module StoreFrontModule
  module Settings
    class UnitOfMeasurementsController < AuthenticatedController
      def edit
        @unit_of_measurement = StoreFrontModule::UnitOfMeasurement.find(params[:id])
      end

      def update
        @unit_of_measurement = StoreFrontModule::UnitOfMeasurement.find(params[:id])
        @unit_of_measurement.update(unit_of_measurement_params)
        if @unit_of_measurement.valid?
          @unit_of_measurement.save
          redirect_to product_url(@unit_of_measurement.product), notice: "updated successfully"
        else
          render :edit
        end
      end

      private
      def unit_of_measurement_params
        params.require(:store_front_module_unit_of_measurement).permit(
          :unit_code,
          :description,
          :quantity,
          :base_measurement,
          :conversion_quantity,
          :base_measurement)
      end
    end
  end
end

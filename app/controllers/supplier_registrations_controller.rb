class SupplierRegistrationsController < AuthenticatedController
	def new
		@supplier = Supplier.new
		authorize @supplier
	end
	def create
		@supplier = Supplier.create(supplier_params)
		authorize @supplier
	end
	private
	def supplier_params
		params.require(:supplier).permit(:business_name, :owner_name, :address, :contact_number)
	end
end

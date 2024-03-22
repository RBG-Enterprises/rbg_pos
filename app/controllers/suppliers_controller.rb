class SuppliersController < AuthenticatedController
	def index
		if params[:search].present?
			@suppliers = Supplier.text_search(params[:search]).paginate(page: params[:page], per_page: 20)
		else
		  @suppliers = Supplier.all.paginate(page: params[:page], per_page: 20)
		end
		authorize @suppliers
	end
	def show
		@supplier = Supplier.find(params[:id])
	end

	def edit
		@supplier = Supplier.find(params[:id])
	end
	def update
		@supplier = Supplier.find(params[:id])
		@supplier.update(supplier_params)
		if @supplier.valid?
			@supplier.save
			redirect_to supplier_url(@supplier), notice: "Supplier updated successfully"
		else
			render :edit
		end
	end

	private
	def supplier_params
		params.require(:supplier).
		permit(:business_name, :owner_name, :contact_number, :address)
	end
end

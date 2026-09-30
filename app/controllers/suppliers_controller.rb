class SuppliersController < ApplicationController
	def index
		suppliers_scope = Supplier.with_attached_avatar
		if params[:search].present?
			@pagy, @suppliers = pagy(suppliers_scope.text_search(params[:search]))
		else
		  @pagy, @suppliers = pagy(suppliers_scope.all)
		end

		respond_to do |format|
			format.html { authorize @suppliers }
			format.json { render json: @suppliers.map { |s| { id: s.id, text: s.business_name } } }
		end
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
		permit(:business_name, :owner_name, :contact_number, :address, :avatar)
	end
end

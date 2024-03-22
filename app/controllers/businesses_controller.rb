class BusinessesController < AuthenticatedController
	def edit
		@business = Business.find(params[:id])
	end
	def update
		@business = Business.find(params[:id])
		@business.update(business_params)
		if @business.save
			redirect_to settings_url, notice: "Business info updated successfully"
		else
			render :edit
		end
	end

	private
	def business_params
		params.require(:business).permit(:name, :owner, :address, :contact_number, :email)
	end
end

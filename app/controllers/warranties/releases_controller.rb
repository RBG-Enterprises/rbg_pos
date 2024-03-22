module Warranties
	class ReleasesController < AuthenticatedController
		def create
			authorize :warranty_release, :new?
			@warranty = Warranty.find(params[:warranty_id])
			@warranty.create_warranty_release!(quantity: @warranty.quantity, release_date: Time.zone.now, user: current_user)
			@warranty.save
			redirect_to warranties_url, notice: "Warranty released successfully."
		end
	end
end

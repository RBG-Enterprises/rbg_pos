class UsersController < ApplicationController
	def new 
		@user = User.new 
		authorize @user
	end 
	def create
		@user = User.create(user_params)
		authorize @user
		if @user.valid?
			@user.save 
			redirect_to settings_url, notice: "Employee registered successfully."
		else 
			render :new 
		end 
	end 
	def edit 
		@user = User.find(params[:id])
    authorize @user
	end
	def update 
		@user = User.find(params[:id])
    authorize @user
		@user.update(user_params)
		if @user.save 
			redirect_to settings_url, notice: "Employee info updated successfully."
		else 
			render :edit 
		end 
	end 


	private
	def user_params
		params.require(:user).permit(:avatar, :email, :password, :password_confirmation, :role, :first_name, :last_name)
	end 
end 
class AccountsController < ApplicationController
  def show
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(params.require(:user).permit(:avatar))
      redirect_to account_path, notice: "Photo updated successfully."
    else
      flash.now[:alert] = "Could not update photo."
      render :show
    end
  end
end

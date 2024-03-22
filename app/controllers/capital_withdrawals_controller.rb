class CapitalWithdrawalsController < AuthenticatedController
  def new
    @withdraw = CapitalWithdrawalForm.new
  end
  def create
    @withdraw = CapitalWithdrawalForm.new(withdrawal_params)
    if @withdraw.valid?
      @withdraw.save
      redirect_to employees_url, notice: "Withdraw saved successfully."
    else
      render :new
    end
  end

  private
  def withdrawal_params
    params.require(:capital_withdrawal_form).permit(:employee_id, :date, :amount)
  end
end

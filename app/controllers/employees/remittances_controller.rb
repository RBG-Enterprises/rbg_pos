module Employees
  class RemittancesController < ApplicationController
    def new
      @employee = User.find(params[:employee_id])
      @entry = AccountingModule::RemittanceForm.new
      @cash_account = AccountingModule::Account.find(params[:cash_account_id])
    end
    # Two-step flow: first POST validates and renders a confirmation page;
    # the transfer is only saved when re-posted with the Confirm button.
    def create
      @employee = User.find(params[:employee_id])
      @entry = AccountingModule::RemittanceForm.new(entry_params)
      set_confirm_accounts
      if params[:back].present?
        render :new
      elsif params[:confirmed].present?
        if @entry.valid?
          created = @entry.save
          session = transfer_session(created)
          if session.present?
            redirect_to cash_register_session_path(session, anchor: "transfers-pane"),
                        notice: "Collection remittance saved successfully."
          else
            redirect_to admin_employee_url(@employee), notice: "Collection remittance saved successfully."
          end
        else
          render :new
        end
      elsif @entry.valid?
        render :confirm
      else
        render :new
      end
    end

    private
    def set_confirm_accounts
      @cash_account = AccountingModule::Account.find_by(id: entry_params[:credit_account_id])
      @debit_account = AccountingModule::Account.find_by(id: entry_params[:debit_account_id])
    end
    # Session that recorded the transfer: prefer the entry's own session,
    # fall back to the cashier's session for the entry date.
    def transfer_session(created_entry)
      return if created_entry.blank?
      return created_entry.cash_register_session if created_entry.cash_register_session.present?

      record_date = created_entry.entry_date.try(:to_date) || Time.zone.today
      @employee.cash_register_session_for(record_date) || @employee.current_cash_register_session
    end
    def entry_params
      params.require(:accounting_module_remittance_form).permit(:recorder_id,:cashier_id, :entry_date, :reference_number, :description, :debit_account_id, :credit_account_id, :amount)
    end
  end
end

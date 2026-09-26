module Accounting
  class AccountsController < ApplicationController
    def index
      respond_to do |format|
        format.html do
          @accounts = AccountingModule::Account.active.all.order(:account_code).all.paginate(page: params[:page], per_page: 35)
        end
        format.json do
          query = ActiveRecord::Base.sanitize_sql_like(params[:search].to_s.strip)
          @accounts = AccountingModule::Asset.active
            .where("name ILIKE :prefix OR account_code ILIKE :prefix", prefix: "#{query}%")
            .order(:name).limit(20)
          render json: @accounts.map { |a| { id: a.id, text: "#{a.name} (#{a.account_code})" } }
        end
      end
    end
    def new
      @account = AccountingModule::Account.new
    end

    def create
      @account = AccountingModule::Account.create(new_account_params)
      if @account.valid?
        @account.save!
        redirect_to accounting_accounts_url, notice: 'Account created successfully'
      else
        render :new
      end
    end

    def show
      @account = AccountingModule::Account.find(params[:id])
      @entries = @account.entries.order(entry_date: :desc).all.paginate(page: params[:page], per_page: 50)
    end
    def edit
      @account = AccountingModule::Account.find(params[:id])
    end
    def update
      @account = AccountingModule::Account.find(params[:id])
      @account.update(account_params)
      if @account.valid?
        @account.save
        redirect_to accounting_accounts_url, notice: "Updated successfully."
      else
        render :edit
      end
    end

    def deactivate
      @account = AccountingModule::Account.find(params[:id])
      @account.deactivate!
      redirect_to accounting_accounts_url, notice: "Account deactivated successfully."
    end

    private
    def account_params
      params.require(require_param).permit(:name, :account_code, :contra, :type, :main_account_id)
    end

    def new_account_params
      params.require(:accounting_module_account).permit(:name, :account_code, :contra, :type, :main_account_id, :business_id)
    end

    def require_param
      @account.type.underscore.parameterize.gsub("-", "_").to_sym
    end
  end
end

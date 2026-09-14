module Employees
  class SettingsController < ApplicationController
    def index
      @employee = User.find(params[:employee_id])
    end
  end
end

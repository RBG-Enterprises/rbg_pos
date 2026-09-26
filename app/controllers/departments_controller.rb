class DepartmentsController < ApplicationController
  def index
    @departments = if params[:search].present?
      Department.joins(:customer).where(
        "departments.name ILIKE :q OR customers.first_name ILIKE :q OR customers.last_name ILIKE :q",
        q: "%#{params[:search]}%"
      )
    else
      Department.all
    end
    @departments = @departments.limit(20)

    respond_to do |format|
      format.json { render json: @departments.map { |d| { id: d.id, text: d.customer_name_and_department } } }
    end
  end
end

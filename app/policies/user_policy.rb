class UserPolicy < ApplicationPolicy
	def index?
		user.proprietor?
	end 
	def new?
		user.proprietor? 
	end 
	def create?
		new?
	end
  def edit?
    user.proprietor?
  end
  def update?
    edit?
  end
  # Anyone may update their own photo; EmployeesController#update only
  # permits :avatar, so this can't escalate anything else.
  def update_avatar?
    user.proprietor? || record == user
  end
end 
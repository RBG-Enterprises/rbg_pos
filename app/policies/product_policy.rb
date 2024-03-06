class ProductPolicy < ApplicationPolicy
	def index?
		true
	end
	def new?
		user.proprietor? || user.warehouse_clerk? || user.sales_clerk?
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
end
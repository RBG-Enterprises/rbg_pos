class SupplierPolicy < ApplicationPolicy
	def index?
		user.proprietor? || user.warehouse_clerk? || user.sales_clerk?
	end
	def new?
		user.proprietor? || user.warehouse_clerk? || user.sales_clerk?
	end
	def create?
		new?
	end
end
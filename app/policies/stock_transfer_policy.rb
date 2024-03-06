class StockTransferPolicy < ApplicationPolicy
	def new?
		user.proprietor? || user.warehouse_clerk? || user.sales_clerk?
	end
end
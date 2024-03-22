class JobOrdersController < AuthenticatedController
	def index
		@job_orders = JobOrder.all
	end
	def new
		@job_order = JobOrder.new
		@job_order.build_unit
	end
	def create
	end
end

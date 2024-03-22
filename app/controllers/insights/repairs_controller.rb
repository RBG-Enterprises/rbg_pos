module Insights
  class RepairsController < AuthenticatedController
    def index
      @receivable_account = current_business.service_revenue_parent_account_category
    end
  end
end

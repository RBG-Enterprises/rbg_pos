class KnowledgeCenterController < AuthenticatedController
  def index
    if params[:search].present?
      @searches = PgSearch.multisearch(params[:search]).paginate(page: params[:page], per_page: 35)
    else
      @work_orders = WorkOrder.all.paginate(page: params[:page], per_page: 35)
    end
  end
end

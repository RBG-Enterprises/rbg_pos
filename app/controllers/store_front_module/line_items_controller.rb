module StoreFrontModule
  class LineItemsController < AuthenticatedController
    def show
      @line_item = LineItem.find(params[:id])
    end
  end
end

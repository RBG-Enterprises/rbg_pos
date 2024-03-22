module StoreFrontModule
  module Orders
    module PurchaseOrders
      class CancellationsController < AuthenticatedController
        def create
          @order = Order.find(params[:purchase_order_id])
          ::
          Orders::Cancellation.new(order: @order).cancel!
          redirect_to "/", notice: 'Order cancelled successfully.'
        end
      end
    end
  end
end

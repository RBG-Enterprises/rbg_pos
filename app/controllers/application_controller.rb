class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }
  before_action :authenticate_user!
  rescue_from Pundit::NotAuthorizedError, with: :permission_denied



  private
  def permission_denied
    redirect_to customers_url, alert: 'Sorry but you are not allowed to access this page.'
  end

  def current_cart
    Cart.find(session[:cart_id])
    rescue ActiveRecord::RecordNotFound
    cart = Cart.create
    session[:cart_id] = cart.id
    cart
  end
end

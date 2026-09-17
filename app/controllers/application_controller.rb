class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend
  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }
  before_action :authenticate_user!
  rescue_from Pundit::NotAuthorizedError, with: :permission_denied
  helper_method :current_store_front, :current_business, :current_cart

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

  def current_store_front
    current_user.store_front
  end

  def current_business
    current_user.business
  end

  # Pairs with the js-report-form/js-report-submit behavior in
  # store_front_module/store_fronts/partials/_reports: the browser polls for
  # this cookie to know the file response has started and stop showing its
  # "Generating..." spinner. Call right before assigning self.response_body.
  def signal_report_download_started
    return if params[:download_token].blank?

    cookies[:report_download_token] = { value: params[:download_token], path: "/" }
  end
end

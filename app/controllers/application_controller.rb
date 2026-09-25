class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend
  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }
  before_action :authenticate_user!
  before_action :ensure_cash_register_session
  rescue_from Pundit::NotAuthorizedError, with: :permission_denied
  helper_method :current_store_front, :current_business, :current_cart, :current_cash_register_session, :cash_register_session_open?

  private

  def current_cash_register_session
    return nil unless current_user&.cashier?

    @current_cash_register_session ||=
      current_user.current_cash_register_session ||
      CashRegisterSessions::OpenForDay.call(employee: current_user)
  end

  # Cashiers must declare their opening float before they can transact.
  # Non-cashiers (no cash drawer assigned) have nothing to open, so they're unrestricted.
  def cash_register_session_open?
    return true unless current_user&.cashier?

    current_cash_register_session.present? && current_cash_register_session.opening_declared_amount.present?
  end

  def ensure_cash_register_session
    return unless user_signed_in?
    return unless current_user.cashier?

    current_cash_register_session
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    nil
  end

  def permission_denied
    redirect_to customers_url, alert: 'Sorry but you are not allowed to access this page.'
  end

  # Only honors an in-app path (never a full/external URL) to avoid an open redirect.
  def safe_return_to(default)
    candidate = params[:return_to].to_s
    candidate.start_with?("/") && !candidate.start_with?("//") ? candidate : default
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

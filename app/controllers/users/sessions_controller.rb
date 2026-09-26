class Users::SessionsController < Devise::SessionsController
  layout 'signin'
# before_filter :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    session.delete(:store_front_id)
    super do |user|
      CashRegisterSessions::OpenForDay.call(employee: user, date: Date.current)
    end
  end

  # DELETE /resource/sign_out
  def destroy
    if current_user && (open_session = current_user.current_cash_register_session)
      redirect_to cash_register_session_path(open_session),
                  alert: "Close your cash register session before logging out." and return
    end

    super
  end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.for(:sign_in) << :attribute
  # end
end

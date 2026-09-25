class CashRegisterSessionsController < ApplicationController
  def index
    filter = CashRegisterSessions::FilterSessions.run!(
      current_user: current_user,
      employee_id: params[:employee_id].presence,
      date: params[:date].presence,
    )

    @can_filter_by_employee = filter.can_filter_by_employee
    @pagy, @cash_register_sessions = pagy(filter.sessions)

    if @can_filter_by_employee
      @selected_cashier = cashiers_scope.find_by(id: params[:employee_id]) if params[:employee_id].present?
      @cashiers = cashiers_scope.text_search(params[:cashier_search]).limit(8) if params[:cashier_search].present?
    end
  end

  def show
    @cash_register_session = find_session
    @orders = @cash_register_session.sales_orders
      .includes(:commercial_document, :line_items, :sales_order_line_items, :other_sales_line_items, :cash_payment)
      .to_a
    @credit_sales_orders = @orders.select(&:credit)
    @transfer_entries = @cash_register_session.transfer_entries
    @cash_receipts = @cash_register_session.cash_receipts
    @items_summary = @cash_register_session.items_summary
    respond_to do |format|
      format.html
      format.pdf do
        pdf = Reports::CashRegisterSessionPdf.new(
          cash_register_session: @cash_register_session,
          orders: @orders,
          credit_sales: @credit_sales_orders,
          transfer_entries: @transfer_entries,
          cash_receipts: @cash_receipts,
          items_summary: @items_summary,
          business: current_business,
          store_front: @cash_register_session.store_front,
          cash_account: @cash_register_session.cash_account,
          employee: @cash_register_session.employee,
          view_context: view_context
        )
        send_data pdf.render, type: 'application/pdf', disposition: 'inline', file_name: eod_filename("pdf")
      end
      format.csv { render_csv }
    end
  end

  def update
    @cash_register_session = find_session
    authorize_session!(@cash_register_session)
    if @cash_register_session.update(session_params)
      redirect_to cash_register_session_path(@cash_register_session), notice: "Cash session updated."
    else
      redirect_to store_index_path, alert: @cash_register_session.errors.full_messages.to_sentence
    end
  end

  def close
    @cash_register_session = find_session
    authorize_session!(@cash_register_session)
    CashRegisterSessions::CloseSession.call(
      session: @cash_register_session,
      counted_amount: params[:closing_declared_amount],
      closing_note: params[:closing_note]
    )
    redirect_to cash_register_session_path(@cash_register_session, format: :pdf),
                notice: "Session closed. EOD report generated."
  end

  private

  def cashiers_scope
    User.where(id: CashRegisterSession.select(:employee_id)).includes(:store_front, avatar_attachment: :blob)
  end

  def find_session
    scope = (current_user.proprietor? || current_user.accountant?) ? CashRegisterSession.all : current_user.cash_register_sessions
    scope.find(params[:id])
  end

  def authorize_session!(session)
    return if current_user.proprietor? || current_user.accountant?
    return if session.employee_id == current_user.id

    raise Pundit::NotAuthorizedError
  end

  def session_params
    params.require(:cash_register_session).permit(:opening_declared_amount, :opening_note, :closing_declared_amount, :closing_note)
  end

  def eod_filename(extension)
    session = @cash_register_session
    "EOD-#{session.employee.try(:full_name).to_s.parameterize}-#{session.session_date}.#{extension}"
  end

  def render_csv
    headers.delete("Content-Length")
    headers["Cache-Control"] = "no-cache"
    headers["Content-Type"] = "text/csv"
    headers["X-Accel-Buffering"] = "no"
    self.response_body = csv_body
    response.status = 200
  end

  def csv_body
    session = @cash_register_session
    Enumerator.new do |yielder|
      yielder << CSV.generate_line(["END OF DAY REPORT"])
      yielder << CSV.generate_line(["Session Date: #{session.session_date.strftime("%b. %e, %Y")}"])
      yielder << CSV.generate_line(["Status: #{session.status.upcase}"])
      yielder << CSV.generate_line([""])
      yielder << CSV.generate_line(["CASHIER", session.employee.try(:full_name).to_s])
      yielder << CSV.generate_line(["CASH ACCOUNT", session.cash_account.try(:name).to_s])
      yielder << CSV.generate_line(["OPENED AT", session.opened_at.try(:strftime, "%b %e, %Y %I:%M %p").to_s])
      yielder << CSV.generate_line(["CLOSED AT", session.closed_at.try(:strftime, "%b %e, %Y %I:%M %p").to_s])
      yielder << CSV.generate_line([""])
      yielder << CSV.generate_line(["CASH SUMMARY"])
      yielder << CSV.generate_line(["BEGINNING BALANCE (SYSTEM)", session.beginning_balance.to_s])
      yielder << CSV.generate_line(["BEGINNING BALANCE (DECLARED)", session.opening_declared_amount.to_s])
      yielder << CSV.generate_line(["CASH RECEIPTS (#{@cash_receipts.count} transactions)", session.cash_receipts_total.to_s])
      yielder << CSV.generate_line(["TRANSFERS IN (#{@transfer_entries.count} entries)", session.transfers_in_total.to_s])
      yielder << CSV.generate_line(["LESS: TRANSFERS (OUT) & REFUNDS", session.cash_credits_total.to_s])
      yielder << CSV.generate_line(["CREDIT SALES - NOT IN DRAWER (#{@credit_sales_orders.count} sales)", session.credit_sales_total.to_s])
      yielder << CSV.generate_line(["DISCOUNTS GIVEN", @orders.to_a.sum(&:discount_amount).to_s])
      yielder << CSV.generate_line(["ENDING BALANCE (EXPECTED)", session.expected_cash.to_s])
      yielder << CSV.generate_line(["ENDING BALANCE (COUNTED)", session.closing_declared_amount.to_s])
      yielder << CSV.generate_line(["VARIANCE (SHORT / OVER)", session.variance_amount.to_s])
      yielder << CSV.generate_line([""])
      yielder << CSV.generate_line(["ITEMS SOLD"])
      yielder << CSV.generate_line(["ITEM", "QTY", "AMOUNT"])
      @items_summary.each do |row|
        yielder << CSV.generate_line([row[:name].to_s, row[:quantity].to_s, row[:amount].to_s])
      end
      yielder << CSV.generate_line([""])
      yielder << CSV.generate_line(["CASH RECEIPTS"])
      yielder << CSV.generate_line(["TIME", "TYPE", "CUSTOMER", "AMOUNT"])
      @cash_receipts.each do |row|
        yielder << CSV.generate_line([
          row[:date].try(:strftime, "%I:%M %p").to_s,
          row[:kind].to_s,
          row[:customer_name].to_s,
          row[:amount].to_s
        ])
      end
      yielder << CSV.generate_line([""])
      yielder << CSV.generate_line(["CREDIT SALES"])
      yielder << CSV.generate_line(["DATE", "OR", "CUSTOMER", "ITEMS", "TOTAL COST"])
      @credit_sales_orders.each do |order|
        description = order.line_items.present? ? order.line_items_name : order.description.to_s
        yielder << CSV.generate_line([
          order.date.try(:strftime, "%B %e, %Y").to_s,
          order.reference_number.to_s,
          order.commercial_document.try(:name).try(:upcase).to_s,
          description,
          order.total_cost_less_discount.to_s
        ])
      end
      yielder << CSV.generate_line([""])
      yielder << CSV.generate_line(["TRANSFERS"])
      yielder << CSV.generate_line(["DATE", "DESCRIPTION", "IN", "OUT"])
      @transfer_entries.each do |entry|
        cash_in = entry.debit_amounts.where(account: session.cash_account).sum(:amount)
        cash_out = entry.credit_amounts.where(account: session.cash_account).sum(:amount)
        yielder << CSV.generate_line([
          entry.entry_date.try(:strftime, "%B %e, %Y %I:%M %p").to_s,
          entry.description.to_s,
          cash_in.zero? ? "" : cash_in.to_s,
          cash_out.zero? ? "" : cash_out.to_s
        ])
      end
    end
  end
end

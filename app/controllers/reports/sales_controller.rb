module Reports
	class SalesController < AuthenticatedController
		def index
			@from_date   = Chronic.parse(params[:from_date].to_date)
      @to_date     = Chronic.parse(params[:to_date].to_date)
      @store_front = StoreFront.find_by(id: params[:store_front_id])
      @employee    = params[:user_id] ? User.find(params[:user_id]) : current_user
      @cash_on_hand_account = @employee.cash_on_hand_account
      if !current_user.proprietor?
        @orders = current_user.sales_orders.ordered_on(from_date: @from_date, to_date: @to_date)
      elsif @store_front.present?
        @orders = @store_front.sales_orders.ordered_on(from_date: @from_date, to_date: @to_date)
      else
			  @orders = StoreFrontModule::Orders::SalesOrder.ordered_on(from_date: @from_date, to_date: @to_date)
      end
			respond_to do |format|
        format.xlsx
        format.csv { render_csv }
				format.pdf do
					pdf = Reports::SalesPdf.new(
            from_date:            @from_date,
            to_date:              @to_date,
            orders:               @orders,
            business:             current_business,
            store_front:          @store_front,
            cash_on_hand_account: @employee.cash_on_hand_account,
            employee:             @employee,
            view_context:         view_context)
          send_data pdf.render, type: 'application/pdf', disposition: 'inline', file_name: 'Sales Report.pdf'
          pdf = nil
		    end
		  end
    end

    private
    def render_csv
      # Tell Rack to stream the content
      headers.delete("Content-Length")

      # Don't cache anything from this generated endpoint
      headers["Cache-Control"] = "no-cache"

      # Tell the browser this is a CSV file
      headers["Content-Type"] = "text/csv"

      # Make the file download with a specific filename

      # Don't buffer when going through proxy servers
      headers["X-Accel-Buffering"] = "no"

      # Set an Enumerator as the body
      self.response_body = csv_body

      response.status = 200
    end

    private

    def csv_body
      Enumerator.new do |yielder|
        yielder << CSV.generate_line(["SALES REPORT"])
        yielder << CSV.generate_line(["Date Covered: #{@from_date.strftime("%b. %e, %Y")} - #{@to_date.strftime("%b. %e, %Y")}"])
        yielder << CSV.generate_line([""])
        yielder << CSV.generate_line(["EMPLOYEE ", "#{@employee.try(:name)}"])
        yielder << CSV.generate_line(["CASH ACCOUNT", "#{@cash_on_hand_account.try(:name)}"])
        yielder << CSV.generate_line(["BEGINNING BALANCE", "#{@cash_on_hand_account.balance(to_date: @to_date.beginning_of_day)}"])
        yielder << CSV.generate_line(["ADD SALES", "#{@cash_on_hand_account.debits_balance(from_date: @from_date, to_date: @to_date) - @employee.received_cash_transfers(from_date: @from_date.beginning_of_day, to_date: @to_date.end_of_day).sum(&:amount) }"])
        yielder << CSV.generate_line(["LESS REMITTANCES", "#{@cash_on_hand_account.credits_balance(from_date: @from_date, to_date: @to_date) }"])
        yielder << CSV.generate_line([""])
        yielder << CSV.generate_line(["ENDING BALANCE", "<b>#{@cash_on_hand_account.balance(to_date: @to_date.end_of_day) }"])

        yielder << CSV.generate_line([""])
        yielder << CSV.generate_line(["Name", "Barcode", "Purchases", "Sales", "Stock Transfers", "Spoilages", "Internal Uses", 'Sales Returns', 'For Warranty', "Available QTY"])

        if @employee.present? && !@employee.proprietor?
          yielder << CSV.generate_line(["DATE", "OR", "CUSTOMER", "ITEMS", "DISCOUNT", "TOTAL COST"])
          @orders.each do |order|
            yielder << CSV.generate_line([
            order.date.strftime("%B %e, %Y"),
            order.reference_number,
            order.commercial_document.try(:name).try(:upcase),
            order_description(order),
            order.discount_amount,
            order.try(:total_cost)])
          end
        else
          yielder << CSV.generate_line(["DATE", "OR", "CUSTOMER", "ITEMS", "COGS", "DISCOUNT", "TOTAL COST", "INCOME"])

          @orders.ordered_on(from_date: (@from_date.beginning_of_day), to_date: @to_date.end_of_day).each do |order|
            yielder << CSV.generate_line([
            order.date.strftime("%B %e, %Y"),
            order.reference_number,
            order.commercial_document.try(:name).try(:upcase),
            order_description(order),
            order.cost_of_goods_sold,
            order.discount_amount,
            order.try(:total_cost),
            order.income])
          end
        end
      end
    end

    def order_description(order)
      if order.line_items.present?
        order.line_items_name
      elsif order.description.present?
        order.description
      end
    end
	end
end

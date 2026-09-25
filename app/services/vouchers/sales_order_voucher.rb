module Vouchers
  class SalesOrderVoucher
    attr_reader :order, :employee, :account_number,
    :cash_on_hand, :sales, :sales_discount, :merchandise_inventory, :cost_of_goods_sold

    def initialize(args)
      @order                 = args.fetch(:order)
      @employee              = args.fetch(:employee)
      @voucher_class         = args[:voucher_class] || Voucher
      @store_front           = @employee.store_front
      @cash_on_hand          = @employee.cash_on_hand_account
      @sales_discount        = @store_front.sales_discount_account
      @sales                 = @order.sales_revenue_account
      @merchandise_inventory = @store_front.merchandise_inventory_account
      @cost_of_goods_sold    = @store_front.cost_of_goods_sold_account
    end
    def create_voucher!
      voucher = @voucher_class.new(
        description: order.line_items_name,
        date: Voucher.transaction_time_for(order.date),
        payee: order.customer,
        preparer: order.employee,
        reference_number: SecureRandom.uuid,
        commercial_document: order,
        account_number: order.account_number,
        cash_register_session: order.cash_register_session
      )

      voucher.voucher_amounts.debit.build(
        amount: order.total_cost_less_discount,
        account: cash_on_hand
      )

      voucher.voucher_amounts.debit.build(
        amount: order.discount_amount,
        account: sales_discount
      )
       voucher.voucher_amounts.debit.build(
        amount: order.cost_of_goods_sold,
        account: cost_of_goods_sold
      )

      #credit_amounts

      voucher.voucher_amounts.credit.build(
        amount: order.total_cost,
        account: sales
      )

      voucher.voucher_amounts.credit.build(
        amount: order.cost_of_goods_sold,
        account: merchandise_inventory
      )
    voucher.save!
    order.update!(voucher: voucher)
    end
  end
end

require 'rails_helper'

module StoreFronts
  describe Stock do
    describe 'associations' do
      it { is_expected.to belong_to :store_front }
      it { is_expected.to belong_to :product }
      it { is_expected.to belong_to :unit_of_measurement }
      it { is_expected.to have_one :purchase }
      it { is_expected.to have_many :sales }
      it { is_expected.to have_many :stock_transfers }
      it { is_expected.to have_many :internal_uses }
      it { is_expected.to have_many :spoilages }
      it { is_expected.to have_many :sales_returns }
      it { is_expected.to have_many :purchase_returns }
      it { is_expected.to have_many :for_warranties }


    end
    it '.processed' do
      stock_1  = create(:stock)
      stock_2  = create(:stock)
      order    = create(:order)
      purchase = create(:purchase_order_line_item, stock: stock_1, order: order)

      expect(described_class.processed).to include(stock_1)
      expect(described_class.processed).to_not include(stock_2)

    end

    it '#balance' do
      stock    = create(:stock)
      entry    = create(:entry_with_credit_and_debit)
      voucher  = create(:voucher, accounting_entry: entry)
      order    = create(:purchase_order, voucher: voucher)
      purchase = create(:purchase_order_line_item, quantity: 100, stock: stock)
      order.line_items << purchase
      expect(stock.balance).to eql 100

      #sales
      sale_entry   = create(:entry_with_credit_and_debit)
      sale_voucher = create(:voucher, accounting_entry: sale_entry)
      sales_order  = create(:sales_order, voucher: sale_voucher)
      sale         = create(:sales_order_line_item, stock: stock, quantity: 10)
      sales_order.line_items << sale
      expect(stock.balance).to eql 90

      #stock_transfers
      transfer_entry   = create(:entry_with_credit_and_debit)
      transfer_voucher = create(:voucher, accounting_entry: transfer_entry)
      transfer_order   = create(:stock_transfer_order, voucher: transfer_order)
      transfer         = create(:stock_transfer_order_line_item, quantity: 10, stock: stock, order: transfer_order)
      expect(stock.balance).to eql 80

      #internal_uses
      internal_entry   = create(:entry_with_credit_and_debit)
      internal_voucher = create(:voucher, accounting_entry: internal_entry)
      internal_order   = create(:internal_use_order, voucher: internal_voucher)
      internal_use     = create(:internal_use_order_line_item, quantity: 10, stock: stock, order: internal_order)

      expect(stock.balance).to eql 70

      #spoilage
      spoilage_entry   = create(:entry_with_credit_and_debit)
      spoilage_voucher = create(:voucher, accounting_entry: spoilage_entry)
      spoilage_order   = create(:internal_use_order, voucher: spoilage_voucher)
      spoilage         = create(:spoilage_order_line_item, quantity: 10, stock: stock, order: spoilage_order)

      expect(stock.balance).to eql 60

      #purchase_returns
      purchase_return_entry   = create(:entry_with_credit_and_debit)
      purchase_return_voucher = create(:voucher, accounting_entry: purchase_return_entry)
      purchase_return_order   = create(:purchase_return_order, voucher: purchase_return_voucher)
      purchase_return         = create(:purchase_return_order_line_item, quantity: 10, stock: stock, order: purchase_return_order)

      expect(stock.balance).to eql 50

      #sales_returns
      sales_return_entry   = create(:entry_with_credit_and_debit)
      sales_return_voucher = create(:voucher, accounting_entry: sales_return_entry)
      sales_return_order   = create(:sales_return_order, voucher: sales_return_voucher)
      sales_return         = create(:sales_return_order_line_item, quantity: 10, stock: stock, order: sales_return_order)

      expect(stock.balance).to eql 60

      #for_warranties
      for_warranty_entry   = create(:entry_with_credit_and_debit)
      for_warranty_voucher = create(:voucher, accounting_entry: for_warranty_entry)
      for_warranty_order   = create(:for_warranty_order, voucher: for_warranty_voucher)
      for_warranty         = create(:for_warranty_order_line_item, quantity: 10, stock: stock, order: for_warranty_order)

      expect(stock.balance).to eql 50
    end
  end
end
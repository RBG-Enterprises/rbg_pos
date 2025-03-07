# frozen_string_literal: true

require "rails_helper"

RSpec.describe StoreFronts::SalesReturns::CreateService, type: :service do
  let(:business) { create(:business) }
  let(:store_front) { create(:store_front) }
  let!(:cash_on_hand_account) { create(:asset, name: "Cash on Hand", business: business) }
  let(:user) do
    create(:sales_clerk, store_front: store_front, business: business, cash_on_hand_account: cash_on_hand_account)
  end

  let(:sales_order) { create(:sales_order, returned_at: nil, employee: user, store_front: store_front) }
  let!(:sales_order_line_item1) { create(:sales_order_line_item, sales_order: sales_order) }
  let!(:sales_order_line_item2) { create(:sales_order_line_item, sales_order: sales_order) }

  let(:service) { described_class.run(sales_order: sales_order, user: user) }

  describe "#execute" do
    context "when sales order is already returned" do
      before { sales_order.update(returned_at: Time.current) }

      it "does not proceed with the return" do
        expect { service }.not_to change { StoreFrontModule::Orders::SalesReturnOrder.count }
      end
    end

    context "when sales order is not yet returned" do
      it "creates a sales return order" do
        expect { service }.to change { StoreFrontModule::Orders::SalesReturnOrder.count }.by(1)
      end

      it "creates return line items" do
        expect { service }.to change { StoreFrontModule::LineItems::SalesReturnOrderLineItem.count }
      end

      it "updates stocks" do
        allow_any_instance_of(StoreFronts::Stock).to receive(:update_available_quantity!).and_call_original
        allow_any_instance_of(StoreFronts::Stock).to receive(:update_availability!).and_call_original
        service
        sales_order.stocks.each do |stock|
          expect(stock).to have_received(:update_available_quantity!)
          expect(stock).to have_received(:update_availability!)
        end
      end

      it "creates an accounting entry" do
        expect { service }.to change { AccountingModule::Entry.count }.by(1)
      end

      it "marks the sales order as returned" do
        service
        expect(sales_order.reload.returned_at).not_to be_nil
      end
    end

    context "when sales order is a credit" do
      before do
        entry = build(:entry)
        entry.debit_amounts.build(amount:  sales_order.total_cost_less_discount, account: sales_order.receivable_account)
        entry.credit_amounts.build(amount: sales_order.total_cost_less_discount, account: sales_order.sales_revenue_account)
        entry.save!
      end

      it "credits sales order receivable account" do
        service

        expect(sales_order.receivable_account.reload.balance).to eq 0
      end
    end
  end
end

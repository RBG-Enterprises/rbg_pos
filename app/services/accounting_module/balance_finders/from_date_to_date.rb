module AccountingModule
  module BalanceFinders
    class FromDateToDate
      attr_reader  :from_date, :to_date, :amounts

      def initialize(args={})
        @amounts   = args.fetch(:amounts).includes(:entry, :account)
        @from_date = args.fetch(:from_date)
        @to_date   = args.fetch(:to_date)
      end

      def compute
        date_range = DateRange.new(from_date: from_date, to_date: to_date)
        amounts.where('entries.entry_date' => date_range.range).total

      end
    end
  end
end

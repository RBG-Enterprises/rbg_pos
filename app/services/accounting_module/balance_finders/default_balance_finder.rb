module AccountingModule
  module BalanceFinders
    class DefaultBalanceFinder
      attr_reader :amounts

      def initialize(args ={})
        @amounts ||= args.fetch(:amounts)
      end

      def compute
        amounts.total
      end
    end
  end
end

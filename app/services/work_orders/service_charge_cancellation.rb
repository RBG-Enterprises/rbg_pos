module WorkOrders
  class ServiceChargeCancellation
    attr_reader :service_charge, :work_order, :employee, :customer
    def initialize(service_charge:)
      @service_charge = service_charge
      @employee       = @service_charge.user
      @work_order     = @service_charge.work_order
      @customer       = @work_order.customer
    end
    def cancel!
      ActiveRecord::Base.transaction do
        delete_entry
        delete_service_charge
      end
    end
    private
    def delete_entry
      if service_charge.entry.present?
        service_charge.entry.destroy
      end
    end

    def delete_service_charge
      service_charge.destroy
    end
  end
end

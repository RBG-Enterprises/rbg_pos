namespace :customers do
  desc "Merge duplicate customers"
  task merge_duplicates: :environment do
    duplicates = Customer
      .select("MIN(id) AS main_id, LOWER(first_name) AS first_name, LOWER(last_name) AS last_name")
      .group("LOWER(first_name), LOWER(last_name)")
      .having("COUNT(*) > 1")

    duplicates.each do |duplicate|
      main_record = Customer.find(duplicate.main_id)

      # Find all other duplicates except the main record
      duplicate_customers = Customer.where("LOWER(first_name) = ? AND LOWER(last_name) = ?", duplicate.first_name, duplicate.last_name)
                                    .where.not(id: main_record.id)

      # Move associated records to the main record (if applicable)
      duplicate_customers.each do |dup|
        dup.orders.update_all(commercial_document_id: main_record.id)
        dup.payments.update_all(commercial_document_id: main_record.id)
        dup.work_orders.update_all(customer_id: main_record.id)
        dup.departments.update_all(customer_id: main_record.id)

        dup.destroy
      end
    end
  end
end

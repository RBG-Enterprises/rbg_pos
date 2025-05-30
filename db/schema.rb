# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_05_30_012535) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accessories", force: :cascade do |t|
    t.bigint "product_unit_id"
    t.decimal "quantity"
    t.string "description"
    t.string "serial_number"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "work_order_id"
    t.index ["product_unit_id"], name: "index_accessories_on_product_unit_id"
    t.index ["work_order_id"], name: "index_accessories_on_work_order_id"
  end

  create_table "account_categories", force: :cascade do |t|
    t.string "title"
    t.string "account_code"
    t.string "type"
    t.boolean "contra", default: false
    t.bigint "business_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "parent_account_category_id"
    t.index ["business_id"], name: "index_account_categories_on_business_id"
    t.index ["parent_account_category_id"], name: "index_account_categories_on_parent_account_category_id"
    t.index ["type"], name: "index_account_categories_on_type"
  end

  create_table "accounts", force: :cascade do |t|
    t.string "name"
    t.string "account_code"
    t.boolean "contra", default: false
    t.string "type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "active", default: true
    t.bigint "business_id"
    t.bigint "account_category_id"
    t.bigint "level_one_account_category_id"
    t.index ["account_category_id"], name: "index_accounts_on_account_category_id"
    t.index ["account_code"], name: "index_accounts_on_account_code", unique: true
    t.index ["business_id"], name: "index_accounts_on_business_id"
    t.index ["level_one_account_category_id"], name: "index_accounts_on_level_one_account_category_id"
    t.index ["name"], name: "index_accounts_on_name", unique: true
    t.index ["type"], name: "index_accounts_on_type"
  end

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", id: :serial, force: :cascade do |t|
    t.string "trackable_type"
    t.integer "trackable_id"
    t.string "owner_type"
    t.integer "owner_id"
    t.string "key"
    t.text "parameters"
    t.string "recipient_type"
    t.integer "recipient_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["owner_id", "owner_type"], name: "index_activities_on_owner_id_and_owner_type"
    t.index ["owner_type", "owner_id"], name: "index_activities_on_owner"
    t.index ["recipient_id", "recipient_type"], name: "index_activities_on_recipient_id_and_recipient_type"
    t.index ["recipient_type", "recipient_id"], name: "index_activities_on_recipient"
    t.index ["trackable_id", "trackable_type"], name: "index_activities_on_trackable_id_and_trackable_type"
    t.index ["trackable_type", "trackable_id"], name: "index_activities_on_trackable"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "amounts", force: :cascade do |t|
    t.bigint "account_id"
    t.bigint "entry_id"
    t.decimal "amount"
    t.string "type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "commercial_document_type"
    t.bigint "commercial_document_id"
    t.index ["account_id", "entry_id"], name: "index_amounts_on_account_id_and_entry_id"
    t.index ["account_id"], name: "index_amounts_on_account_id"
    t.index ["commercial_document_type", "commercial_document_id"], name: "index_commercial_document_on_amounts"
    t.index ["entry_id", "account_id"], name: "index_amounts_on_entry_id_and_account_id"
    t.index ["entry_id"], name: "index_amounts_on_entry_id"
    t.index ["type"], name: "index_amounts_on_type"
  end

  create_table "bank_accounts", force: :cascade do |t|
    t.string "account_number"
    t.string "bank_name"
    t.bigint "cash_in_bank_account_id"
    t.bigint "business_id"
    t.datetime "date", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["business_id"], name: "index_bank_accounts_on_business_id"
    t.index ["cash_in_bank_account_id"], name: "index_bank_accounts_on_cash_in_bank_account_id"
  end

  create_table "bill_counts", force: :cascade do |t|
    t.bigint "bill_id"
    t.decimal "bill_count"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "cash_count_id"
    t.index ["bill_id"], name: "index_bill_counts_on_bill_id"
    t.index ["cash_count_id"], name: "index_bill_counts_on_cash_count_id"
  end

  create_table "bills", force: :cascade do |t|
    t.string "name"
    t.string "amount"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "business_account_configs", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.bigint "service_receivable_category_id", null: false
    t.bigint "service_revenue_category_id", null: false
    t.bigint "sales_receivable_category_id", null: false
    t.bigint "sales_revenue_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_business_account_configs_on_business_id"
    t.index ["sales_receivable_category_id"], name: "index_sales_rec_categories_on_business_configs"
    t.index ["sales_revenue_category_id"], name: "index_sales_rev_categories_on_business_configs"
    t.index ["service_receivable_category_id"], name: "index_service_rec_categories_on_business_configs"
    t.index ["service_revenue_category_id"], name: "index_service_rev_categories_on_business_configs"
  end

  create_table "businesses", force: :cascade do |t|
    t.string "name"
    t.string "owner"
    t.string "address"
    t.string "email"
    t.string "contact_number"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "service_revenue_parent_account_category_id"
    t.bigint "sales_revenue_parent_account_category_id"
    t.bigint "service_receivable_parent_account_category_id"
    t.index ["sales_revenue_parent_account_category_id"], name: "index_businesses_on_sales_revenue_parent_account_category_id"
    t.index ["service_receivable_parent_account_category_id"], name: "index_service_receivable_parent_account_category_on_businesses"
    t.index ["service_revenue_parent_account_category_id"], name: "index_businesses_on_service_revenue_parent_account_category_id"
  end

  create_table "carts", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "cash_counts", force: :cascade do |t|
    t.bigint "employee_id"
    t.datetime "date", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["employee_id"], name: "index_cash_counts_on_employee_id"
  end

  create_table "cash_payments", force: :cascade do |t|
    t.decimal "cash_tendered"
    t.decimal "cash_change"
    t.string "cash_paymentable_type"
    t.bigint "cash_paymentable_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "discount_amount"
    t.index ["cash_paymentable_type", "cash_paymentable_id"], name: "index_paymentable_on_cash_payments"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "contact_number"
    t.string "address"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "avatar_file_name"
    t.string "avatar_content_type"
    t.bigint "avatar_file_size"
    t.datetime "avatar_updated_at", precision: nil
    t.boolean "enable_interest", default: false
    t.bigint "business_id"
    t.bigint "receivable_account_id"
    t.string "account_number"
    t.bigint "service_revenue_account_id"
    t.bigint "sales_revenue_account_id"
    t.bigint "sales_discount_account_id"
    t.decimal "receivable_balance", default: "0.0"
    t.index ["account_number"], name: "index_customers_on_account_number", unique: true
    t.index ["business_id"], name: "index_customers_on_business_id"
    t.index ["receivable_account_id"], name: "index_customers_on_receivable_account_id"
    t.index ["receivable_balance"], name: "index_customers_on_receivable_balance"
    t.index ["sales_discount_account_id"], name: "index_customers_on_sales_discount_account_id"
    t.index ["sales_revenue_account_id"], name: "index_customers_on_sales_revenue_account_id"
    t.index ["service_revenue_account_id"], name: "index_customers_on_service_revenue_account_id"
  end

  create_table "departments", force: :cascade do |t|
    t.string "name"
    t.bigint "customer_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["customer_id"], name: "index_departments_on_customer_id"
  end

  create_table "employee_cash_accounts", force: :cascade do |t|
    t.bigint "employee_id"
    t.bigint "cash_account_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["cash_account_id"], name: "index_employee_cash_accounts_on_cash_account_id"
    t.index ["employee_id"], name: "index_employee_cash_accounts_on_employee_id"
  end

  create_table "entries", force: :cascade do |t|
    t.string "reference_number"
    t.datetime "entry_date", precision: nil
    t.string "commercial_document_type"
    t.bigint "commercial_document_id"
    t.string "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "entry_type"
    t.bigint "user_id"
    t.bigint "recorder_id"
    t.index ["commercial_document_type", "commercial_document_id"], name: "index_on_commercial_document_entry"
    t.index ["entry_type"], name: "index_entries_on_entry_type"
    t.index ["recorder_id"], name: "index_entries_on_recorder_id"
    t.index ["user_id"], name: "index_entries_on_user_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.string "type"
    t.string "number"
    t.string "invoiceable_type"
    t.bigint "invoiceable_id"
    t.datetime "date", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["invoiceable_type", "invoiceable_id"], name: "index_invoices_on_invoiceable_type_and_invoiceable_id"
    t.index ["type"], name: "index_invoices_on_type"
  end

  create_table "ledger_accounts", force: :cascade do |t|
    t.string "ledgerable_type"
    t.bigint "ledgerable_id"
    t.bigint "account_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["account_id"], name: "index_ledger_accounts_on_account_id"
    t.index ["ledgerable_type", "ledgerable_id"], name: "index_ledger_accounts_on_ledgerable_type_and_ledgerable_id"
  end

  create_table "level_one_account_categories", force: :cascade do |t|
    t.string "title"
    t.string "code"
    t.string "type"
    t.bigint "store_front_id", null: false
    t.boolean "contra", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_front_id"], name: "index_level_one_account_categories_on_store_front_id"
    t.index ["type"], name: "index_level_one_account_categories_on_type"
  end

  create_table "line_items", force: :cascade do |t|
    t.bigint "cart_id"
    t.decimal "unit_cost"
    t.decimal "total_cost"
    t.decimal "quantity"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "order_id"
    t.bigint "user_id"
    t.string "search"
    t.string "type"
    t.bigint "referenced_line_item_id"
    t.bigint "product_id"
    t.bigint "unit_of_measurement_id"
    t.bigint "sales_order_line_item_id"
    t.bigint "purchase_order_line_item_id"
    t.string "bar_code"
    t.string "commercial_document_type"
    t.bigint "commercial_document_id"
    t.string "referencer_type"
    t.bigint "referencer_id"
    t.bigint "registry_id"
    t.datetime "date", precision: nil
    t.bigint "store_front_id"
    t.bigint "stock_id"
    t.bigint "destination_store_front_id"
    t.index ["cart_id"], name: "index_line_items_on_cart_id"
    t.index ["commercial_document_type", "commercial_document_id"], name: "index_commercial_document_on_line_items"
    t.index ["destination_store_front_id"], name: "index_line_items_on_destination_store_front_id"
    t.index ["order_id"], name: "index_line_items_on_order_id"
    t.index ["product_id"], name: "index_line_items_on_product_id"
    t.index ["purchase_order_line_item_id"], name: "index_line_items_on_purchase_order_line_item_id"
    t.index ["referenced_line_item_id"], name: "index_line_items_on_referenced_line_item_id"
    t.index ["referencer_type", "referencer_id"], name: "index_line_items_on_referencer_type_and_referencer_id"
    t.index ["registry_id"], name: "index_line_items_on_registry_id"
    t.index ["sales_order_line_item_id"], name: "index_line_items_on_sales_order_line_item_id"
    t.index ["stock_id"], name: "index_line_items_on_stock_id"
    t.index ["store_front_id"], name: "index_line_items_on_store_front_id"
    t.index ["type"], name: "index_line_items_on_type"
    t.index ["unit_of_measurement_id"], name: "index_line_items_on_unit_of_measurement_id"
    t.index ["user_id"], name: "index_line_items_on_user_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "date", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "employee_id"
    t.string "reference_number"
    t.string "description"
    t.string "search_term"
    t.string "type"
    t.string "commercial_document_type"
    t.bigint "commercial_document_id"
    t.bigint "destination_store_front_id"
    t.boolean "credit", default: false
    t.bigint "voucher_id"
    t.bigint "store_front_id"
    t.string "account_number"
    t.string "supplier_type"
    t.bigint "supplier_id"
    t.bigint "receivable_account_id"
    t.bigint "sales_revenue_account_id"
    t.bigint "sales_discount_account_id"
    t.bigint "payable_account_id"
    t.bigint "department_id"
    t.datetime "returned_at", precision: nil
    t.index ["account_number"], name: "index_orders_on_account_number", unique: true
    t.index ["commercial_document_type", "commercial_document_id"], name: "index_commercial_document_on_orders"
    t.index ["department_id"], name: "index_orders_on_department_id"
    t.index ["destination_store_front_id"], name: "index_orders_on_destination_store_front_id"
    t.index ["employee_id"], name: "index_orders_on_employee_id"
    t.index ["payable_account_id"], name: "index_orders_on_payable_account_id"
    t.index ["receivable_account_id"], name: "index_orders_on_receivable_account_id"
    t.index ["reference_number"], name: "index_orders_on_reference_number"
    t.index ["sales_discount_account_id"], name: "index_orders_on_sales_discount_account_id"
    t.index ["sales_revenue_account_id"], name: "index_orders_on_sales_revenue_account_id"
    t.index ["store_front_id"], name: "index_orders_on_store_front_id"
    t.index ["supplier_type", "supplier_id"], name: "index_orders_on_supplier_type_and_supplier_id"
    t.index ["type"], name: "index_orders_on_type"
    t.index ["voucher_id"], name: "index_orders_on_voucher_id"
  end

  create_table "other_sales_line_items", force: :cascade do |t|
    t.decimal "amount"
    t.string "description"
    t.string "reference_number"
    t.datetime "date", precision: nil
    t.bigint "order_id"
    t.bigint "cart_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["cart_id"], name: "index_other_sales_line_items_on_cart_id"
    t.index ["order_id"], name: "index_other_sales_line_items_on_order_id"
  end

  create_table "parent_account_categories", force: :cascade do |t|
    t.string "title"
    t.string "account_code"
    t.string "type"
    t.bigint "business_id", null: false
    t.boolean "contra", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_parent_account_categories_on_business_id"
    t.index ["type"], name: "index_parent_account_categories_on_type"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "order_id"
    t.integer "mode_of_payment"
    t.decimal "discount_amount", default: "0.0"
    t.decimal "cash_tendered"
    t.decimal "change"
    t.decimal "total_cost"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "total_cost_less_discount"
    t.index ["order_id"], name: "index_payments_on_order_id"
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.string "searchable_type"
    t.bigint "searchable_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable_type_and_searchable_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "updateable_type"
    t.bigint "updateable_id"
    t.string "type"
    t.string "title"
    t.string "content"
    t.datetime "date", precision: nil
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["type"], name: "index_posts_on_type"
    t.index ["updateable_type", "updateable_id"], name: "index_posts_on_updateable_type_and_updateable_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "product_units", force: :cascade do |t|
    t.string "description"
    t.string "model_number"
    t.string "serial_number"
    t.text "physical_condition"
    t.text "reported_problem"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "service_number"
    t.bigint "customer_id"
    t.index ["customer_id"], name: "index_product_units_on_customer_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "unit"
    t.decimal "retail_price"
    t.decimal "wholesale_price"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "avatar_file_name"
    t.string "avatar_content_type"
    t.bigint "avatar_file_size"
    t.datetime "avatar_updated_at", precision: nil
    t.bigint "category_id"
    t.decimal "low_stock_count", default: "0.0"
    t.bigint "business_id"
    t.index ["business_id"], name: "index_products_on_business_id"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["name"], name: "index_products_on_name", unique: true
  end

  create_table "purchase_orders", force: :cascade do |t|
    t.string "supplier_type", null: false
    t.bigint "supplier_id", null: false
    t.bigint "voucher_id", null: false
    t.string "account_number"
    t.bigint "employee_id", null: false
    t.bigint "store_front_id", null: false
    t.bigint "receivable_account_id", null: false
    t.datetime "date", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "payable_account_id"
    t.index ["employee_id"], name: "index_purchase_orders_on_employee_id"
    t.index ["payable_account_id"], name: "index_purchase_orders_on_payable_account_id"
    t.index ["receivable_account_id"], name: "index_purchase_orders_on_receivable_account_id"
    t.index ["store_front_id"], name: "index_purchase_orders_on_store_front_id"
    t.index ["supplier_type", "supplier_id"], name: "index_purchase_orders_on_supplier_type_and_supplier_id"
    t.index ["voucher_id"], name: "index_purchase_orders_on_voucher_id"
  end

  create_table "purchase_prices", force: :cascade do |t|
    t.bigint "product_id"
    t.bigint "unit_of_measurement_id"
    t.bigint "store_front_id"
    t.decimal "price"
    t.datetime "date", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["product_id"], name: "index_purchase_prices_on_product_id"
    t.index ["store_front_id"], name: "index_purchase_prices_on_store_front_id"
    t.index ["unit_of_measurement_id"], name: "index_purchase_prices_on_unit_of_measurement_id"
  end

  create_table "registries", force: :cascade do |t|
    t.string "spreadsheet_file_name"
    t.string "spreadsheet_content_type"
    t.bigint "spreadsheet_file_size"
    t.datetime "spreadsheet_updated_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "type"
    t.bigint "employee_id"
    t.index ["employee_id"], name: "index_registries_on_employee_id"
    t.index ["type"], name: "index_registries_on_type"
  end

  create_table "repairs", force: :cascade do |t|
    t.text "symptoms_observed"
    t.text "repair_description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "sections", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "selling_prices", force: :cascade do |t|
    t.decimal "price"
    t.bigint "unit_of_measurement_id"
    t.bigint "product_id"
    t.datetime "date", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "store_front_id"
    t.index ["product_id"], name: "index_selling_prices_on_product_id"
    t.index ["store_front_id"], name: "index_selling_prices_on_store_front_id"
    t.index ["unit_of_measurement_id"], name: "index_selling_prices_on_unit_of_measurement_id"
  end

  create_table "service_charges", force: :cascade do |t|
    t.string "description"
    t.decimal "amount"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "charge_type"
    t.index ["charge_type"], name: "index_service_charges_on_charge_type"
  end

  create_table "stocks", force: :cascade do |t|
    t.bigint "product_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "store_front_id"
    t.string "barcode"
    t.bigint "unit_of_measurement_id"
    t.boolean "available", default: false
    t.decimal "available_quantity", default: "0.0"
    t.boolean "is_processed", default: false, null: false
    t.index ["barcode"], name: "index_stocks_on_barcode"
    t.index ["is_processed"], name: "index_stocks_on_is_processed"
    t.index ["product_id"], name: "index_stocks_on_product_id"
    t.index ["store_front_id"], name: "index_stocks_on_store_front_id"
    t.index ["unit_of_measurement_id"], name: "index_stocks_on_unit_of_measurement_id"
  end

  create_table "store_front_accounts", force: :cascade do |t|
    t.bigint "store_front_id"
    t.bigint "account_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["account_id"], name: "index_store_front_accounts_on_account_id"
    t.index ["store_front_id"], name: "index_store_front_accounts_on_store_front_id"
  end

  create_table "store_front_configs", force: :cascade do |t|
    t.bigint "accounts_receivable_account_id"
    t.bigint "store_front_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["accounts_receivable_account_id"], name: "index_store_front_configs_on_accounts_receivable_account_id"
    t.index ["store_front_id"], name: "index_store_front_configs_on_store_front_id"
  end

  create_table "store_fronts", force: :cascade do |t|
    t.bigint "business_id"
    t.bigint "merchandise_inventory_account_id"
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "address"
    t.bigint "cost_of_goods_sold_account_id"
    t.bigint "sales_return_account_id"
    t.bigint "sales_account_id"
    t.bigint "sales_discount_account_id"
    t.bigint "receivable_account_id"
    t.bigint "internal_use_account_id"
    t.bigint "purchase_return_account_id"
    t.bigint "spoilage_account_id"
    t.bigint "service_revenue_account_id"
    t.bigint "service_receivable_account_category_id"
    t.bigint "sales_revenue_account_category_id"
    t.datetime "deactivated_at", precision: nil
    t.index ["business_id"], name: "index_store_fronts_on_business_id"
    t.index ["cost_of_goods_sold_account_id"], name: "index_store_fronts_on_cost_of_goods_sold_account_id"
    t.index ["internal_use_account_id"], name: "index_store_fronts_on_internal_use_account_id"
    t.index ["merchandise_inventory_account_id"], name: "index_store_fronts_on_merchandise_inventory_account_id"
    t.index ["name"], name: "index_store_fronts_on_name", unique: true
    t.index ["purchase_return_account_id"], name: "index_store_fronts_on_purchase_return_account_id"
    t.index ["receivable_account_id"], name: "index_store_fronts_on_receivable_account_id"
    t.index ["sales_account_id"], name: "index_store_fronts_on_sales_account_id"
    t.index ["sales_discount_account_id"], name: "index_store_fronts_on_sales_discount_account_id"
    t.index ["sales_return_account_id"], name: "index_store_fronts_on_sales_return_account_id"
    t.index ["sales_revenue_account_category_id"], name: "index_store_fronts_on_sales_revenue_account_category_id"
    t.index ["service_receivable_account_category_id"], name: "index_store_fronts_on_service_receivable_account_category_id"
    t.index ["service_revenue_account_id"], name: "index_store_fronts_on_service_revenue_account_id"
    t.index ["spoilage_account_id"], name: "index_store_fronts_on_spoilage_account_id"
  end

  create_table "sub_accounts", force: :cascade do |t|
    t.bigint "main_account_id"
    t.bigint "sub_account_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["main_account_id"], name: "index_sub_accounts_on_main_account_id"
    t.index ["sub_account_id"], name: "index_sub_accounts_on_sub_account_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "business_name"
    t.string "owner_name"
    t.string "address"
    t.string "contact_number"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "payable_account_id"
    t.string "avatar_file_name"
    t.string "avatar_content_type"
    t.bigint "avatar_file_size"
    t.datetime "avatar_updated_at", precision: nil
    t.index ["business_name"], name: "index_suppliers_on_business_name", unique: true
    t.index ["payable_account_id"], name: "index_suppliers_on_payable_account_id"
  end

  create_table "technician_work_orders", force: :cascade do |t|
    t.bigint "technician_id"
    t.bigint "work_order_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["technician_id"], name: "index_technician_work_orders_on_technician_id"
    t.index ["work_order_id"], name: "index_technician_work_orders_on_work_order_id"
  end

  create_table "unit_of_measurements", force: :cascade do |t|
    t.bigint "product_id"
    t.string "unit_code"
    t.string "description"
    t.decimal "quantity"
    t.decimal "conversion_quantity"
    t.boolean "base_measurement", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["product_id"], name: "index_unit_of_measurements_on_product_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "first_name"
    t.string "last_name"
    t.integer "role"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "avatar_file_name"
    t.string "avatar_content_type"
    t.bigint "avatar_file_size"
    t.datetime "avatar_updated_at", precision: nil
    t.string "designation"
    t.bigint "section_id"
    t.bigint "cash_on_hand_account_id"
    t.bigint "store_front_id"
    t.bigint "business_id"
    t.datetime "deactivated_at", precision: nil
    t.index ["business_id"], name: "index_users_on_business_id"
    t.index ["cash_on_hand_account_id"], name: "index_users_on_cash_on_hand_account_id"
    t.index ["deactivated_at"], name: "index_users_on_deactivated_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["section_id"], name: "index_users_on_section_id"
    t.index ["store_front_id"], name: "index_users_on_store_front_id"
  end

  create_table "voucher_amounts", force: :cascade do |t|
    t.decimal "amount"
    t.bigint "account_id"
    t.bigint "voucher_id"
    t.string "commercial_document_type"
    t.bigint "commercial_document_id"
    t.string "description"
    t.integer "amount_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "recorder_id"
    t.bigint "cart_id"
    t.index ["account_id"], name: "index_voucher_amounts_on_account_id"
    t.index ["amount_type"], name: "index_voucher_amounts_on_amount_type"
    t.index ["cart_id"], name: "index_voucher_amounts_on_cart_id"
    t.index ["commercial_document_type", "commercial_document_id"], name: "index_commercial_document_on_voucher_amounts"
    t.index ["recorder_id"], name: "index_voucher_amounts_on_recorder_id"
    t.index ["voucher_id"], name: "index_voucher_amounts_on_voucher_id"
  end

  create_table "vouchers", force: :cascade do |t|
    t.datetime "date", precision: nil
    t.string "payee_type"
    t.bigint "payee_id"
    t.string "description"
    t.decimal "payable_amount"
    t.string "type"
    t.bigint "preparer_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "reference_number"
    t.string "commercial_document_type"
    t.bigint "commercial_document_id"
    t.string "account_number"
    t.bigint "entry_id"
    t.index ["account_number"], name: "index_vouchers_on_account_number", unique: true
    t.index ["commercial_document_type", "commercial_document_id"], name: "index_commercial_document_on_vouchers"
    t.index ["entry_id"], name: "index_vouchers_on_entry_id"
    t.index ["payee_type", "payee_id"], name: "index_vouchers_on_payee_type_and_payee_id"
    t.index ["preparer_id"], name: "index_vouchers_on_preparer_id"
    t.index ["reference_number"], name: "index_vouchers_on_reference_number", unique: true
    t.index ["type"], name: "index_vouchers_on_type"
  end

  create_table "work_order_categories", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["title"], name: "index_work_order_categories_on_title", unique: true
  end

  create_table "work_order_service_charges", force: :cascade do |t|
    t.bigint "service_charge_id"
    t.bigint "work_order_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "user_id"
    t.index ["service_charge_id"], name: "index_work_order_service_charges_on_service_charge_id"
    t.index ["user_id"], name: "index_work_order_service_charges_on_user_id"
    t.index ["work_order_id"], name: "index_work_order_service_charges_on_work_order_id"
  end

  create_table "work_orders", force: :cascade do |t|
    t.integer "status"
    t.bigint "product_unit_id"
    t.bigint "customer_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "reported_problem"
    t.string "physical_condition"
    t.string "service_number"
    t.boolean "under_warranty", default: false
    t.integer "supplier_id"
    t.datetime "purchase_date", precision: nil
    t.datetime "expiry_date", precision: nil
    t.string "customer_name"
    t.string "product_name"
    t.bigint "section_id"
    t.bigint "store_front_id"
    t.string "contact_person"
    t.datetime "release_date", precision: nil
    t.datetime "date_received", precision: nil
    t.bigint "receivable_account_id"
    t.bigint "sales_discount_account_id"
    t.bigint "service_revenue_account_id"
    t.string "account_number"
    t.bigint "work_order_category_id"
    t.bigint "sales_revenue_account_id"
    t.bigint "department_id"
    t.bigint "technician_id"
    t.index ["account_number"], name: "index_work_orders_on_account_number", unique: true
    t.index ["customer_id"], name: "index_work_orders_on_customer_id"
    t.index ["department_id"], name: "index_work_orders_on_department_id"
    t.index ["product_unit_id"], name: "index_work_orders_on_product_unit_id"
    t.index ["receivable_account_id"], name: "index_work_orders_on_receivable_account_id"
    t.index ["sales_discount_account_id"], name: "index_work_orders_on_sales_discount_account_id"
    t.index ["sales_revenue_account_id"], name: "index_work_orders_on_sales_revenue_account_id"
    t.index ["section_id"], name: "index_work_orders_on_section_id"
    t.index ["service_revenue_account_id"], name: "index_work_orders_on_service_revenue_account_id"
    t.index ["status"], name: "index_work_orders_on_status"
    t.index ["store_front_id"], name: "index_work_orders_on_store_front_id"
    t.index ["technician_id"], name: "index_work_orders_on_technician_id"
    t.index ["work_order_category_id"], name: "index_work_orders_on_work_order_category_id"
  end

  add_foreign_key "accessories", "product_units"
  add_foreign_key "accessories", "work_orders"
  add_foreign_key "account_categories", "businesses"
  add_foreign_key "account_categories", "parent_account_categories"
  add_foreign_key "accounts", "account_categories"
  add_foreign_key "accounts", "businesses"
  add_foreign_key "accounts", "level_one_account_categories"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "amounts", "accounts"
  add_foreign_key "amounts", "entries"
  add_foreign_key "bank_accounts", "accounts", column: "cash_in_bank_account_id"
  add_foreign_key "bank_accounts", "businesses"
  add_foreign_key "bill_counts", "bills"
  add_foreign_key "bill_counts", "cash_counts"
  add_foreign_key "business_account_configs", "businesses"
  add_foreign_key "business_account_configs", "parent_account_categories", column: "sales_receivable_category_id"
  add_foreign_key "business_account_configs", "parent_account_categories", column: "sales_revenue_category_id"
  add_foreign_key "business_account_configs", "parent_account_categories", column: "service_receivable_category_id"
  add_foreign_key "business_account_configs", "parent_account_categories", column: "service_revenue_category_id"
  add_foreign_key "businesses", "parent_account_categories", column: "sales_revenue_parent_account_category_id"
  add_foreign_key "businesses", "parent_account_categories", column: "service_receivable_parent_account_category_id"
  add_foreign_key "businesses", "parent_account_categories", column: "service_revenue_parent_account_category_id"
  add_foreign_key "cash_counts", "users", column: "employee_id"
  add_foreign_key "customers", "accounts", column: "receivable_account_id"
  add_foreign_key "customers", "accounts", column: "sales_discount_account_id"
  add_foreign_key "customers", "accounts", column: "sales_revenue_account_id"
  add_foreign_key "customers", "accounts", column: "service_revenue_account_id"
  add_foreign_key "customers", "businesses"
  add_foreign_key "departments", "customers"
  add_foreign_key "employee_cash_accounts", "accounts", column: "cash_account_id"
  add_foreign_key "employee_cash_accounts", "users", column: "employee_id"
  add_foreign_key "entries", "users"
  add_foreign_key "entries", "users", column: "recorder_id"
  add_foreign_key "ledger_accounts", "accounts"
  add_foreign_key "level_one_account_categories", "store_fronts"
  add_foreign_key "line_items", "carts"
  add_foreign_key "line_items", "line_items", column: "purchase_order_line_item_id"
  add_foreign_key "line_items", "line_items", column: "referenced_line_item_id"
  add_foreign_key "line_items", "line_items", column: "sales_order_line_item_id"
  add_foreign_key "line_items", "orders"
  add_foreign_key "line_items", "products"
  add_foreign_key "line_items", "registries"
  add_foreign_key "line_items", "stocks"
  add_foreign_key "line_items", "store_fronts"
  add_foreign_key "line_items", "store_fronts", column: "destination_store_front_id"
  add_foreign_key "line_items", "unit_of_measurements"
  add_foreign_key "line_items", "users"
  add_foreign_key "orders", "accounts", column: "payable_account_id"
  add_foreign_key "orders", "accounts", column: "receivable_account_id"
  add_foreign_key "orders", "accounts", column: "sales_discount_account_id"
  add_foreign_key "orders", "accounts", column: "sales_revenue_account_id"
  add_foreign_key "orders", "departments"
  add_foreign_key "orders", "store_fronts"
  add_foreign_key "orders", "store_fronts", column: "destination_store_front_id"
  add_foreign_key "orders", "users", column: "employee_id"
  add_foreign_key "orders", "vouchers"
  add_foreign_key "other_sales_line_items", "carts"
  add_foreign_key "other_sales_line_items", "orders"
  add_foreign_key "parent_account_categories", "businesses"
  add_foreign_key "payments", "orders"
  add_foreign_key "posts", "users"
  add_foreign_key "product_units", "customers"
  add_foreign_key "products", "businesses"
  add_foreign_key "products", "categories"
  add_foreign_key "purchase_orders", "accounts", column: "payable_account_id"
  add_foreign_key "purchase_orders", "accounts", column: "receivable_account_id"
  add_foreign_key "purchase_orders", "store_fronts"
  add_foreign_key "purchase_orders", "users", column: "employee_id"
  add_foreign_key "purchase_orders", "vouchers"
  add_foreign_key "purchase_prices", "products"
  add_foreign_key "purchase_prices", "store_fronts"
  add_foreign_key "purchase_prices", "unit_of_measurements"
  add_foreign_key "registries", "users", column: "employee_id"
  add_foreign_key "selling_prices", "store_fronts"
  add_foreign_key "stocks", "products"
  add_foreign_key "stocks", "store_fronts"
  add_foreign_key "stocks", "unit_of_measurements"
  add_foreign_key "store_front_accounts", "accounts"
  add_foreign_key "store_front_accounts", "store_fronts"
  add_foreign_key "store_front_configs", "accounts", column: "accounts_receivable_account_id"
  add_foreign_key "store_front_configs", "store_fronts"
  add_foreign_key "store_fronts", "account_categories", column: "sales_revenue_account_category_id"
  add_foreign_key "store_fronts", "account_categories", column: "service_receivable_account_category_id"
  add_foreign_key "store_fronts", "accounts", column: "cost_of_goods_sold_account_id"
  add_foreign_key "store_fronts", "accounts", column: "internal_use_account_id"
  add_foreign_key "store_fronts", "accounts", column: "merchandise_inventory_account_id"
  add_foreign_key "store_fronts", "accounts", column: "purchase_return_account_id"
  add_foreign_key "store_fronts", "accounts", column: "receivable_account_id"
  add_foreign_key "store_fronts", "accounts", column: "sales_account_id"
  add_foreign_key "store_fronts", "accounts", column: "sales_discount_account_id"
  add_foreign_key "store_fronts", "accounts", column: "sales_return_account_id"
  add_foreign_key "store_fronts", "accounts", column: "service_revenue_account_id"
  add_foreign_key "store_fronts", "accounts", column: "spoilage_account_id"
  add_foreign_key "store_fronts", "businesses"
  add_foreign_key "sub_accounts", "accounts", column: "main_account_id"
  add_foreign_key "sub_accounts", "accounts", column: "sub_account_id"
  add_foreign_key "suppliers", "accounts", column: "payable_account_id"
  add_foreign_key "technician_work_orders", "users", column: "technician_id"
  add_foreign_key "technician_work_orders", "work_orders"
  add_foreign_key "unit_of_measurements", "products"
  add_foreign_key "users", "accounts", column: "cash_on_hand_account_id"
  add_foreign_key "users", "businesses"
  add_foreign_key "users", "sections"
  add_foreign_key "users", "store_fronts"
  add_foreign_key "voucher_amounts", "accounts"
  add_foreign_key "voucher_amounts", "carts"
  add_foreign_key "voucher_amounts", "users", column: "recorder_id"
  add_foreign_key "voucher_amounts", "vouchers"
  add_foreign_key "vouchers", "entries"
  add_foreign_key "vouchers", "users", column: "preparer_id"
  add_foreign_key "work_order_service_charges", "service_charges"
  add_foreign_key "work_order_service_charges", "users"
  add_foreign_key "work_order_service_charges", "work_orders"
  add_foreign_key "work_orders", "accounts", column: "receivable_account_id"
  add_foreign_key "work_orders", "accounts", column: "sales_discount_account_id"
  add_foreign_key "work_orders", "accounts", column: "sales_revenue_account_id"
  add_foreign_key "work_orders", "accounts", column: "service_revenue_account_id"
  add_foreign_key "work_orders", "customers"
  add_foreign_key "work_orders", "departments"
  add_foreign_key "work_orders", "product_units"
  add_foreign_key "work_orders", "sections"
  add_foreign_key "work_orders", "store_fronts"
  add_foreign_key "work_orders", "users", column: "technician_id"
  add_foreign_key "work_orders", "work_order_categories"
end

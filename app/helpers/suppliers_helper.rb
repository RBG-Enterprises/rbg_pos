module SuppliersHelper
  # Returns an <img> tag for the supplier logo.
  # Falls back to app/assets/images/default.png when no avatar is attached
  # OR when the attached file is missing from storage (e.g. storage was
  # wiped after the auto-attached defaults were saved), so old records
  # never render a broken image.
  def supplier_logo(supplier, height: 50, width: 50, css_class: "img-circle")
    if supplier_logo_available?(supplier)
      image_tag(supplier.avatar, height: height, width: width, class: css_class, alt: supplier.business_name)
    else
      image_tag("default.png", height: height, width: width, class: css_class, alt: supplier.try(:business_name) || "Supplier")
    end
  end

  private

  def supplier_logo_available?(supplier)
    return false if supplier.blank? || !supplier.avatar.attached?
    blob = supplier.avatar.blob
    return false if blob.nil?
    blob.service.exist?(blob.key)
  rescue StandardError
    # If the storage check itself fails (e.g. permissions), attempt render.
    true
  end
end

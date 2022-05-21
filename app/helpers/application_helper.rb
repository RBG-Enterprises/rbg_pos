module ApplicationHelper
  include Pagy::Frontend
  def flash_class(level)
    case level
      when :notice then "alert alert-info"
      when :success then "alert alert-success"
      when :error then "alert alert-error"
      when :alert then "alert alert-alert"
    end
  end


  def site_name
    "RBG Point of Sale"
  end

  def site_url
    # Our dev & test URL
    "http://localhost:3000"
  end

  def meta_author
    # Change the value below between the quotes.
    "ITWORX Technology Services"
  end

  def meta_description
    # Change the value below between the quotes.
    "crafting creative and high quality web applications"
  end

  def meta_keywords
    # Change the value below between the quotes.
    "point of sale"
  end

  # Returns the full title on a per-page basis.
  # No need to change any of this we set page_title and site_name elsewhere.
  def full_title(page_title)
    if page_title.empty?
      site_name
    else
      "#{page_title}"
    end
  end
end

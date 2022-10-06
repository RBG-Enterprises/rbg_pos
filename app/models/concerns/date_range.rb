DateRange = Struct.new(:from_date, :to_date, keyword_init: true) do
  def range
    start_date..end_date
  end

  def start_date
    return from_date.beginning_of_day if from_date.is_a?(Date) || from_date.is_a?(DateTime)

    Time.zone.parse(from_date.to_s).beginning_of_day
  end

  def end_date
    return to_date.end_of_day if to_date.is_a?(Date) || to_date.is_a?(DateTime)

    Time.zone.parse(to_date.to_s).end_of_day
  end
end

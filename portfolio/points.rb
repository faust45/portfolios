module Portfolio::Points
  def operation_point(operation)
    point_from_cache(Portfolio::Points::InOperationPoint, operation)
  end

  def date_point(date)
    point_from_cache(Portfolio::Points::InDatePoint, date)
  end

  def present_point
    point_from_cache(Portfolio::Points::InPresentPoint)
  end

  def point_from_cache(klass, *args)
    @points_cache ||= {}
    @points_cache[[klass] + args] ||= klass.new(self, *args)
  end
end

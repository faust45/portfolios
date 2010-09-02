class Portfolio::Points::InDatePoint < Portfolio::Points::InPresentPoint
  def initialize(portfolio, date)
    super(portfolio)
    @date = date
  end

  def operations
    @operations.before_operation(to_i)
  end

  def operations_after
    @operations.after_operation(to_i)
  end

  def last_operation
    @last_operation ||= @operations.before_date(@date).last || NilObject
  end

  def join_on_conditions
    "portfolio_operations.number <= #{to_i}"
  end

  def in_present?; false; end
end

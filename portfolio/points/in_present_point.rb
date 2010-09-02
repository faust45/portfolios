class Portfolio::Points::InPresentPoint
  attr_reader :date
  alias :in_date :date

  def initialize(portfolio)
    @portfolio = portfolio 
    @operations = portfolio.portfolio_operations
    @date = Date.today
  end

  def retrive
    @last_operation = nil
  end

  def operations
    @operations
  end

  def operations_raw
    @operations
  end

  #No operations in future
  def operations_after; []; end

  def last_operation
    @last_operation ||= @operations.last || NilObject
  end

  def to_i 
    last_operation.number.to_i 
  end

  def join_on_conditions
  end

  def in_present?; true; end
  def in_past?; !in_present?; end
end

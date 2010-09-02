class Portfolio::Points::InOperationPoint < Portfolio::Points::InDatePoint
  def initialize(portfolio, operation)
    super(portfolio, operation.date)
    @last_operation = operation
  end

  def last_operation 
    @last_operation 
  end

  def retrive
  end
end

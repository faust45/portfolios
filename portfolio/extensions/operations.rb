module Portfolio::Extensions::Operations
  def create_buy!(attrs = {})
    self.add Portfolio::Operation::Buy.new(attrs)
  end

  def create_sell!(attrs = {})
    self.add Portfolio::Operation::Sell.new(attrs)
  end

  def create_put_cash!(attrs = {})
    self.add Portfolio::Operation::PutCash.new(attrs)
  end

  def create_get_cash!(attrs = {})
    self.add Portfolio::Operation::GetCash.new(attrs)
  end

  def today
    self.on_date(@owner.in_date)
  end

  protected 
  def add(operation)
    self << operation

    raise Portfolio::OperationInvalid.new(operation) if operation.break?

    operation
  end
end


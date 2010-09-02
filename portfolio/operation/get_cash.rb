class Portfolio::Operation::GetCash < Portfolio::Operation::CashOperation

  validate :validate_insufficient_funds, :unless => :break?
  validate :late_operations_not_break, :if => :in_past?, :unless => :break?

  def human_type
    'Вывод денег'
  end

  protected
  def create_opposite_operation
    self.portfolio.cash << self.amount_abs
  end

  private
  def add_sign_to_amount
    self.amount = self.amount * -1
  end
end

module Portfolio::Operation::CashBehaviourForTrainingPortfolio
  def portfolio_cost_after_operation
    self.portfolio_cost_before_operation + self.amount
  end

end


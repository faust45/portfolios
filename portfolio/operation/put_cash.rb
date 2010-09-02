class Portfolio::Operation::PutCash < Portfolio::Operation::CashOperation


  with_options :if => :is_first_operation? do |o|
    o.after_create  :update_portfolio_first_operation_date_after_create

    o.after_destroy :clear_day_costs
    o.after_destroy :update_portfolio_first_operation_date_after_destroy
  end


  def human_type
    'Ввод денег'
  end

  protected
  def create_opposite_operation
    self.portfolio.cash >> self.amount_abs
  end

  private
  def add_sign_to_amount
    self.amount = self.amount * 1
  end

  def update_portfolio_first_operation_date_after_create
    self.portfolio_without_proxy.update_attribute(:first_operation_date, self.created_at.to_date)
  end

  def update_portfolio_first_operation_date_after_destroy
    date =
      self.portfolio.do_in_present do
        self.portfolio.operations.first.try(:date)
      end

    self.portfolio_without_proxy.update_attribute(:first_operation_date, date)
  end

  def clear_day_costs
    if any_operations?
      date = self.portfolio.first_operation.date - 1.day
      self.portfolio.day_costs.before_date(date).delete_all
    else
      self.portfolio.day_costs.delete_all
    end
  end

  def any_operations?
    self.portfolio.do_in_present do
      self.portfolio.operations.any?
    end
  end
end


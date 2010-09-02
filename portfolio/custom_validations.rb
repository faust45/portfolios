module Portfolio::CustomValidations
  def self.included(base)
  end

  def validate_insufficient_funds
    unless self.break?
      portfolio = self.portfolio_proxy
      portfolio_cash_balance = portfolio.cash.balance
      amount_abs = self.calc_amount.abs

      if portfolio_cash_balance < amount_abs
        msg_desc = {:needs => amount_abs, :avaliable => portfolio_cash_balance}
          if in_past?
            msg_desc[:date_in_past] = self.created_at.to_s(:ru)
          end

        raise Portfolio::InsufficientFunds.new(nil, msg_desc)
      end
    end
  end

  def late_operations_not_break
    balance = self.portfolio_proxy.cash.balance - self.amount_abs

    portfolio_proxy.operations_after_all.each do |op|
      balance += op.amount
      if balance < 0
        raise Portfolio::BreakLateOperations.new(op)
      end
    end
  end

  def portfolio_not_in_archive
    if self.portfolio_proxy.archive?
      raise Portfolio::CannotOperateWithArchivePortfolio.new
    end
  end

  def break?
    self.errors.any?
  end

  def for_real_portfolio?
    RealPortfolio === self.portfolio_proxy
  end

  def for_real_portfolio_in_present?
    for_real_portfolio? and in_present?
  end

  def for_training_portfolio?
    (self.portfolio_proxy || self.portfolio).training?
  end

  def in_present?
    self.portfolio_proxy.in_present?
  end

  def in_past?
    self.portfolio_proxy.in_past?
  end

  def for_training_portfolio_in_past?
    for_training_portfolio? and in_past?
  end

  def for_real_portfolio_if_blank?
    for_real_portfolio? and self.tool_price.blank?
  end

  def for_training_portfolio_in_present_if_blank?
    for_training_portfolio? and in_present? and self.tool_price.blank?
  end

  def for_training_portfolio_in_past_if_blank?
    for_training_portfolio? and in_past? and self.tool_price.blank?
  end
end

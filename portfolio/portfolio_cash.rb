class Portfolio::PortfolioCash
  def initialize(portfolio)
    @portfolio = portfolio
  end

  def balance
    @portfolio.operations.sum(:amount)
  end

  def put(money)
    @portfolio.operations_raw.create_put_cash!(:amount => money)
  end

  def get(money)
    @portfolio.operations_raw.create_get_cash!(:amount => money)
  end

  def <<(money)
    put(money)
  end

  def >>(money)
    get(money)
  end

  def portion
    cost = @portfolio.cost

    unless cost.nil? or cost == 0.0
      balance / @portfolio.cost
    else
      0.0
    end
  end

  def operations
    @portfolio.operations.cash
  end

  def operations_all
    @operations_all ||= operations.all
  end

  def operations_in_period(period)
    operations.in_period(period)
  end

  def amount_today
    self.operations.today.sum(:amount)
  end

  def to_s
    balance.to_s
  end

  memoize :balance, :amount_today, :portion
end

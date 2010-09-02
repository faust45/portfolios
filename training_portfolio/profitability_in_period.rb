class TrainingPortfolio::ProfitabilityInPeriod < Portfolio::ProfitabilityInPeriodBase

  def calc_profitability
    if @period.first_date == @portfolio.live_period.first_date
      @profitability.mul(profitability_in_portfolio_first_date(points.first))
    end

    super
  end

  def profitability_in_portfolio_first_date(point)
    point.portfolio_cost_after_operation / point.cash_amount
  end

  def points 
    returning [] do |points|
      points << DatePoint.new(@portfolio, @period.first_date) unless operations_by_date[@period.first_date]

      dates = operations_by_date.keys
      dates.each do |date|
        points << CashPoint.new(@portfolio, date, operations_by_date[date])
      end

      points << DatePoint.new(@portfolio, @period.last_date)  unless operations_by_date[@period.last_date]
    end
  end
  memoize :points

  def operations_by_date
    returning ActiveSupport::OrderedHash.new do |operations_by_date|
      cash_operations.each do |operation|
        operations_by_date[operation.date] ||= []
        operations_by_date[operation.date] << operation
      end
    end
  end
  memoize :operations_by_date


  class CashPoint
    def initialize(portfolio, date, operations)
      @portfolio = portfolio
      @date = date
      @operations = operations
    end

    def portfolio_cost_after_operation
      @portfolio.cost!(@date)
    end

    def portfolio_cost_before_operation
      @portfolio.cost!(@date) - cash_amount
    end

    def cash_amount
      @operations.sum(&:amount)
    end
  end
end

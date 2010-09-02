class Portfolio::ProfitabilityInPeriodBase
  #Abstract Class
  attr_reader :period

  def initialize(portfolio, period)
    @portfolio = portfolio

    @period =
      period.is_a?(Period) ? period : Period.new(period, :before => @portfolio.in_date)

    unless @portfolio.live_period.include?(@period)
      raise InvalidPeriod.new(@period, @portfolio.live_period)
    end
  end

  def value(in_yearly = nil)
    in_yearly == :in_yearly ? self.in_yearly : self.to_f
  end

  def to_f
    @profitability = ProfitabilityValue.new

    calc_profitability
    @profitability.to_f
  end
  memoize :to_f

  def in_yearly
    365 * self.to_f / ((@period.days / 1.day) + 1)
  end

  private
  def calc_profitability
    points.from(1).inject(points.first) do |point, next_point|
      @profitability.mul(profitability_in_period_without_cash_operations(point, next_point))
      next_point
    end
  end

  def profitability_in_period_without_cash_operations(point, next_point)
    next_point.portfolio_cost_before_operation / point.portfolio_cost_after_operation
  end

  def cash_operations
    @period == @portfolio.live_period ?
      @portfolio.cash.operations_all : @portfolio.cash.operations_in_period(@period)
  end
  memoize :cash_operations


  class ProfitabilityValue
    def initialize(profitability = 1.0)
      @profitability_value = profitability
    end

    def mul(profitability)
      if profitability.to_f.number? && profitability.to_f.nonzero?
        @profitability_value *= profitability.to_f
      end

      self
    end

    def to_f
      #Зачем -1 ??  b - a / a = b/a - 1   (a - стоимость в начале периода  b - в конце периода)
      (@profitability_value - 1) * 100
    end

    module Blank
      class << self
        def to_f(*args); end
        def value(*args); end
        def blank?; true end
      end
    end
  end


  class DatePoint
    def initialize(portfolio, date)
      @portfolio = portfolio
      @date = date
    end

    def portfolio_cost
      @portfolio.cost!(@date)
    end
    alias :portfolio_cost_after_operation :portfolio_cost
    alias :portfolio_cost_before_operation :portfolio_cost
  end


  class InvalidPeriod < Exception
    def initialize(period, live_period)
      @period = period
      @live_period = live_period
    end

    def to_s
      "Период #{@period.to_s} не входит в период жизни портфеля #{@live_period.to_s}"
    end
  end
end

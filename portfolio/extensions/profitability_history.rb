module Portfolio::Extensions::ProfitabilityHistory
  def create(year_period)
    period = create_period(year_period)
    super(:history_period => year_period,
          :profitability => @owner.profitability(period))
  end

  def create_period(year_period)
    #+1.day потаму что в RealPortfolio::ProfitabilityInPeriod идёт расчёт за предыдущий день
    first_date = (@owner.in_date - year_period.duration).end_of_month + 1.day
    Period.new(first_date,  @owner.in_date)
  end
end

class RealPortfolio::ProfitabilityInPeriod < Portfolio::ProfitabilityInPeriodBase

  def points
    points = []
    if @portfolio.live_period.first_date < @period.first_date
      #-1.day нам нужна цена на начало дня
      points << DatePoint.new(@portfolio, @period.first_date - 1.day) 
    end

    points += cash_operations
    points << DatePoint.new(@portfolio, @period.last_date)

    points
  end
end

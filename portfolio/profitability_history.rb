class Portfolio::ProfitabilityHistory < ActiveRecord::Base
  set_table_name :portfolio_profitability_history

  belongs_to :portfolio

  options = { :mapping => [%w(date first_date), %w(period_type to_db)], 
              :converter => :parse }

  with_options options do |op|
    op.composed_of :history_period, :class_name => 'YearPeriod'

    op.composed_of :year,        :class_name => 'Year'
    op.composed_of :half_year,   :class_name => 'HalfYear'
    op.composed_of :quarter,     :class_name => 'Quarter'
    op.composed_of :month,       :class_name => 'Month'
  end

  can_search do
    scoped_by :year,      :scope => :composed
    scoped_by :month,     :scope => :composed
    scoped_by :quarter,   :scope => :composed
    scoped_by :half_year, :scope => :composed
  end

  def self.proccess(month = nil)
    RealPortfolio.public.active.live_period_include(Month.prev).find_each(:batch_size => 100) do |portfolio|
      month ||= portfolio.live_period.first_month

      # за текущий месяц доходность не попадает в историю поэтому Month.prev
      YearPeriod.each_period(month..Month.prev) do |year_period|
        portfolio.do_in_date(year_period.end_date) do
          if portfolio.live_period >= year_period.duration
            portfolio.profitability_history.create(year_period)
          end
        end
      end
    end
  end

  def year
    month.year
  end
end

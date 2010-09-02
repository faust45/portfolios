class Portfolio::Operation::CashOperation < Portfolio::Operation
  #Abstract class
  set_table_name 'portfolio_operations'

  TYPES = {:put => 'Portfolio::Operation::PutCash', :get => 'Portfolio::Operation::GetCash'}

  validates_presence_of     :amount, :message => 'amount_required:Укажите сумму.'
  validates_numericality_of :amount, :message => 'amount_invalid:Сумма денег должна содержать только цифры.', :unless => :break?
  validates_numericality_of :amount, :greater_than => 0, :message => 'amount_lte_zero:Сумма должна быть больше нуля.', :unless => :break?

  before_create :add_sign_to_amount
  before_create :assign_portfolio_cost_before_operation, :if => :for_real_portfolio?

  after_create  :recalc_portfolio_day_costs, :if => :for_training_portfolio_in_past?


  def with_cash?
    true
  end

  def with_tool?
    false
  end

  #For real_portfolios only
  def portfolio_cost_after_operation
    self.portfolio_cost_before_operation + self.amount
  end

  def calc_amount
    self.amount
  end

  def date
    self.created_at.to_date
  end

  protected
  def assign_time
    unless self.created_at.today?
      self.created_at = Time.parse(self.created_at.to_date.to_s + " 18:45")
    end
  end

  def assign_portfolio_cost_before_operation
    self.portfolio_cost_before_operation = self.portfolio_proxy.cost.to_f
  end

  def recalc_portfolio_day_costs
    self.portfolio.day_costs.begining_from_date(self.date).update_all("cost = cost + #{self.amount}")

    self.portfolio.do_in_present do
      first_operation, second_operation = self.portfolio.operations.all(:limit => 2)

    if self == first_operation
      last_date = second_operation.try(:date) || Date.today

      period = (self.date .. last_date - 1.day)
      if period.any?
        working_days = Exchange.working_days(period)
        working_days_hash = {}
        working_days.each {|date| working_days_hash[date] = true }

        values = []
        period.each do |date|
          values << "(#{self.portfolio_id}, '#{date.to_s(:db)}', #{self.amount}, #{working_days_hash.has_key?(date)})"
        end

        self.connection.insert(<<-SQL)
          INSERT INTO #{self.portfolio.day_costs.table_name}
          (portfolio_id, date, cost, is_working_day)
          VALUES #{values.join(',')}
        SQL
      end
      end
    end
  end
end

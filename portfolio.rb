class Portfolio < ActiveRecord::Base
  include Exceptions
  include Points
  include MoveInPast
  include Extensions::BeforeAddOperation
  include FerretSearch
  include PostSort
  include CacheBehaviour

  DEFAULT_NAME = 'Без имени'
  LABELS = {
    :name => 'Имя портфеля',
    :type => 'Тип портфеля',
    :access_type => 'Доступ',
    :cash => 'Сумма денег, руб.'
  }.freeze


  ACCESS_TYPES = [:private, :friends, :public]
  SETTINGS = [:access_type, :archive, :name]

  SORT_FIELDS = [:cost, :profitability_in_yearly, :day_profitability, :date]
  SORT_FUN = {
    :profitability_in_yearly => proc{|p| p.profitability_in_yearly },
    :day_profitability => proc{|p| p.profitability(1.day)},
    :date => proc{|p| p.created_at.to_date}
  }

  attr_accessible :name, :access_type, :archive
  escape_in_view :name

  delegate :buy, :sell, :to => :packets

  has_many :portfolio_operations, :class_name => 'Portfolio::Operation', :before_add => [:assign_portfolio_proxy, :assign_date, :assign_number],
                                  :extend => [ Extensions::Operations, Extensions::DeleteAllMethod ]
  has_many :packets, :include => :tool, :before_add => [:assign_portfolio_proxy], :class_name => 'Portfolio::Packet',
                     :extend => [ Extensions::PacketOperations, Extensions::LoadPackets, Extensions::DeleteAllMethod ]
  has_many :stop_orders, :before_add => [:assign_portfolio_proxy, :assign_date], :class_name => 'Portfolio::StopOrder',
                         :extend => [ Extensions::StopOrders, Extensions::DeleteAllMethod ]
  has_many :day_costs, :class_name => 'Portfolio::DayCost',
                       :extend => [ Extensions::CalcDayCosts, Extensions::DeleteAllMethod ]
  has_many :rating_list, :class_name => 'Portfolio::RatingList',
                         :extend => [ Extensions::RatingList, Extensions::DeleteAllMethod ]
  has_many :profitability_history, :extend => [ Extensions::ProfitabilityHistory, Extensions::DeleteAllMethod ]

  belongs_to :user, :counter_cache => true

  validates_presence_of   :user_id, :message => 'Укажите пользователя'
  validates_presence_of   :user_id, :message => 'Укажите пользователя'
  validates_presence_of   :user,    :message => 'Указаный пользователь не существует', :if => :user_id?
  validates_presence_of   :name,    :message => 'Укажите имя портфеля'
  validates_uniqueness_of :name,    :scope => :user_id, :message => 'name_not_uniq:У вас уже есть портфель с таким именем'
  validates_presence_of   :type,    :message => 'Выберите тип портфеля'
  validates_presence_of   :access_type, :message => 'Выберите уровень доступа к портфелю'
  validates_inclusion_of  :access_type, :in => ACCESS_TYPES, :message => 'Выбран недопустимый уровень доступа', :unless => :break?
  validates_inclusion_of  :type,    :in => ['RealPortfolio', 'TrainingPortfolio'],
                                    :message => 'Выбран недопустимый тип портфеля',
                                    :if => proc {|record| record.errors.on(:type).blank? }

  after_update :count_public

  named_scope :public, :conditions => {:access_type => :public}
  named_scope :visible_for_user, lambda {|user|
    conditions =
      if user.is_a?(User)
        ["user_id = ? OR access_type = ?", user.id, :public]
      else
        ["access_type = ?", :public]
      end

    {:conditions => conditions}
  }
  named_scope :active,  :conditions => {:archive => false}
  named_scope :archive, :conditions => {:archive => true}
  named_scope :live_period_include, lambda { |period|
    { :conditions => ["first_operation_date <= ?", period.first_date] }
  }
  named_scope :age_gt, lambda { |duration|
    { :conditions => ["first_operation_date < ?", duration.ago.to_date] }
  }



  def cash
    PortfolioCash.new(self)
  end

  def cost(date = nil)
    date ||= self.in_date
    date = date.to_date

    date.today? ? calculate_cost :
                  cost_on_date(date)
  end

  def cost!(date = nil)
    cost(date) || (raise CostIsAbsent.new("Portfolio cost on #{date || self.in_date} is absent"))
  end

  def calculate_cost
    packets.cost + cash.balance
  end

  def day_profit
    if self.age > 1.day
      cost_today   = self.cost!
      cash_today   = self.cash.amount_today
      cost_in_begining_of_day = self.cost!(self.in_date - 1.day)

      cost_today - cash_today - cost_in_begining_of_day
    else
      self.packets.profit
    end

  rescue CostIsAbsent => ex
    nil
  end

  def profitability_today
    day_profit ?
      day_profit / cost! * 100 : nil

  rescue ZeroDivisionError, CostIsAbsent => ex
    nil
  end

  def profitability(period = nil)
    if period == 1.day
      return profitability_today
    end

    create_profitability(period).value

  rescue ProfitabilityInPeriodBase::InvalidPeriod, CostIsAbsent => ex
    ProfitabilityInPeriodBase::ProfitabilityValue::Blank
  end

  def profitability_in_yearly
    create_profitability.value(:in_yearly)

  rescue ProfitabilityInPeriodBase::InvalidPeriod, CostIsAbsent => ex
    ProfitabilityInPeriodBase::ProfitabilityValue::Blank
  end

  def age
    self.live_period.days
  end

  def live_period
    if self.first_operation_date
      if self.first_operation_date <= self.in_date
        return Period.new(self.first_operation_date, self.in_date)
      end
    end

    Period::NilPeriod
  end

  def public?
    self.access_type == :public
  end

  def in_archive?
    archive == true
  end

  def published
    public? && !in_archive?
  end

  def last_date_with_cost
    self.day_costs.last_date_with_cost
  end
  memoize :last_date_with_cost

  def move_in_last_active_date
    self.move_in_past(last_date_with_cost)
  end

  def waiting_update?
    if age > 1.day
      return true unless last_date_with_cost

      if self.in_present?
        last_date_with_cost < (self.in_date - 1.day)
      else
        last_date_with_cost < self.in_date
      end
    else
      false
    end
  end

  def update_settings(settings = {})
    if settings.is_a?(Hash)
      settings = settings.reject{|k, _| !SETTINGS.include?(k.to_sym)}
      self.attributes = settings

      if self.archive_changed?
        self.to_archive_date = self.in_archive? ?
          Date.today : nil
      end

      self.save
    end
  end

  def delete
    transaction do
      %w(portfolio_operations
         stop_orders packets
         rating_list
         profitability_history).each do |association_name|

        association = self.send(association_name)
        association.send(:delete_all)
      end

      super
    end
  end

  def amchart_data_full
    day_costs.asc(:date).only_working_days.map do |day_cost|
      [day_cost.date, day_cost.cost]
    end
  end

  def chart_title
    name_raw
  end

  def chart_short
    name_raw
  end

  def chart_type
    'portfolios'
  end

  def to_params
    {:login => self.user.login, :id => self.id}
  end

  class << self
    def find_one(id, options = {})
      super(id, options)

    rescue ActiveRecord::RecordNotFound
      raise Portfolio::NotFound
    end

    def next_default_name
      names = self.all_default_names

      numbers = []
      names.each do |name|
        m = name.match(/#{Portfolio::DEFAULT_NAME}\s(\d+)/)
        if m
          numbers << m[1].to_i
        end
      end

      next_num = numbers.blank? ? 1 : numbers.max + 1
      Portfolio::DEFAULT_NAME + " #{next_num}"
    end
  end

  private
  def create_profitability(period = nil)
    unless self.packets.operations.blank?
      period ||= self.live_period
      self.class::ProfitabilityInPeriod.new(self, period)
    else
      ProfitabilityInPeriodBase::ProfitabilityValue::Blank
    end
  end

  def cost_on_date(date)
    @cost_cache ||= {}
    @cost_cache[date] ||= day_costs.on_date(date)
  end

  def count_public
    user.portfolios_public_count = user.portfolios.public.count
    user.save(false)
  end

  def self.ferret_fields
    [ :name_raw ]
  end

  def self.all_default_names
    self.find_attrs(:name, :conditions => "name like '%#{Portfolio::DEFAULT_NAME}%'")
  end

  cache_on_point :create_profitability, :cash, :live_period, :age, :cost

  class NotFound  < PortfolioException; end
  class DuplicateName < PortfolioException; end
end

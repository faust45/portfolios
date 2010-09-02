class Portfolio::StopOrder < ActiveRecord::Base
  include Portfolio::CustomValidations::DateValidations


  #Assign from params
  attr_accessor :portfolio_proxy, :limit_type
  attr_accessible :quantity, :money, :stop_price, :tool, :tool_id, :tool_type, :limit_date, :limit_type

  delegate :in_past?, :in_present?, :to => :portfolio_proxy

  belongs_to :portfolio
  belongs_to :tool, :polymorphic => true

  before_validation :prepare_stop_price
  before_validation :assign_time, :if => :in_past?

  after_create :try_apply

  validates_presence_of   :portfolio_id, :message => 'portfolio_required'
  validates_presence_of   :tool_id,      :message => 'tool_required'
  validates_presence_of   :tool_type,    :message => 'tool_type_required',  :unless => :break?
  validates_presence_of   :type,         :message => 'order_type_required',  :unless => :break?
  validates_presence_of   :stop_price,   :message => 'stop_price_required', :unless => :break?
  validates_numericality_of :stop_price, :greater_than => 0,
                                         :message => 'stop_price_invalid',
                                         :unless => :break?
  validate :presence_of_money_or_quantity,                                  :unless => :break?
  validate :exclusive_presence_of_money_and_quantity,                       :unless => :break?
  validates_presence_of :limit_type, :message => 'limit_type_required', :unless => :break?
  validates_presence_of :limit_date, :message => 'limit_date_required', :if => :is_limited?
  validate_date_format(:limit_date,  :if => :limit_date?)


  can_search do
    scoped_by :s_date, :attribute => :created_at, :scope => :sort, :alias => 'date'
    scoped_by :s_limit_date, :attribute => :limit_date, :scope => :sort, :alias => 'limit_date'
    scoped_by :s_type, :attribute => :type,    :scope => :sort, :alias => 'type'
    scoped_by :s_stop_price, :attribute => :stop_price, :scope => :sort, :alias => 'stop_price'
    scoped_by :s_quantity, :attribute => :quantity, :scope => :sort, :alias => 'quantity'
    scoped_by :s_amount, :attribute => :money, :scope => :sort, :alias => 'amount'
    scoped_by :s_status, :attribute => :completed, :scope => :sort, :alias => 'status'

    scoped_by :date, :attribute => :created_at,  :scope => :date
    scoped_by :period, :attribute => :created_at, :scope => :date_range
    scoped_by :tool, :through => 'Share', :through_attribute => 'tool_id'
    scoped_by :completed, :scope => {:completed => true}
    scoped_by :active, :scope => {:completed => true}
  end

  named_scope :active, :conditions => {:completed => false}
  named_scope :completed, :conditions => {:completed => true}

  named_scope :expired, lambda {
    { :conditions => [ 'limit_date < ?', Date.today ] }
  }

  named_scope :not_expired, lambda {
    { :conditions => [ '(limit_date IS NULL) OR (limit_date >= ?)', Date.today ] }
  }

  def first
    self.desc(:created_at).find(:first, :limit => 1)
  end

  def portfolio_with_proxy
    portfolio_proxy || portfolio_without_proxy
  end
  alias_method_chain :portfolio, :proxy

  def apply(quotes)
    apply!(quotes)
    true
  rescue Portfolio::OperationInvalid => ex
    logger.error(ex.inspect + ' in method apply ' + self.class.to_s + ex.operation.errors.inspect)
    false
  end

  def human_status
    self.completed ? 'удовлетворена' : 'активная'
  end

  def was_apply?
    @was_apply ||= false
  end

  protected
  def mark_as_completed
    self.update_attribute(:completed, true)
  end

  private
  def try_apply
    if in_present?
      quotes = tool.quotes_recent
      if quotes && can_apply?(quotes)
        @was_apply = apply(quotes)
      end
    else
      if quotes = tool.quote_days.after_date(created_at.to_date).asc(:date).first(:conditions => [close_condition, stop_price])
        @was_apply =
          portfolio.do_in_date(quotes.date) do
            apply(quotes)
          end
      end
    end

  rescue Portfolio::BreakLateOperations => ex
    raise Portfolio::StopOrderBreakLateOperations.new(ex.break_operation)
  rescue Portfolio::OperationException, Exchange::NotWorking
  end

  def assign_time
    self.created_at = Time.parse(self.created_at.to_date.to_s + " 18:45")
  end

  def presence_of_money_or_quantity
    if self.money.nil? and self.quantity.nil?
      self.errors.add_to_base('money_or_quantity_required')
    end
  end

  def exclusive_presence_of_money_and_quantity
    if self.money and self.quantity
      self.errors.add_to_base('quantity_or_money_exclusive_required')
    end
  end

  def is_limited?
    self.limit_type == 'lim'
  end

  def prepare_stop_price
    unless self.stop_price_before_type_cast.blank?
      self.stop_price_before_type_cast.gsub!(/\s/, '')
      self.stop_price_before_type_cast.gsub!(',', '.')
    end
  end
end

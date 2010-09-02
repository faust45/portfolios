class Portfolio::Operation < ActiveRecord::Base
  # Важно! Сохранять полные имена в таблице, чтобы избежать пробелм с поиском файлов дочернего класса
  self.store_full_sti_class = true

  include Portfolio::CustomValidations
  include Portfolio::CustomValidations::DateValidations

  attr_accessor :portfolio_proxy

  set_table_name 'portfolio_operations'

  belongs_to :portfolio
  belongs_to :tool, :polymorphic => true

  before_validation :assign_time, :if => :in_past?

  before_create :recalc_operation_numbers, :if => :in_past?

  after_create  :kill_cache

  before_destroy :create_opposite_operation_before_destroy
  after_destroy  :delete_opposite_operation
  after_destroy  :kill_cache
  after_destroy  :recalc_operation_numbers_after_destroy


  validate :portfolio_not_in_archive
  validate_date_format(:created_at)
  validate_date_in_period(:created_at, :msg_in_past => 'Операции можно совершать начиная с 1 января 2000 года.',
                                       :msg_in_future => 'Совершать операции в будущем нельзя.')

  date_scopes
  default_scope :order => 'number ASC'
  named_scope :cash,    :conditions => {:type => CashOperation::TYPES.values}
  named_scope :put,     :conditions => {:type => CashOperation::TYPES[:put]}
  named_scope :get,     :conditions => {:type => CashOperation::TYPES[:get]}
  named_scope :packets, :conditions => {:type => PacketOperation::TYPES.values}
  named_scope :buy,     :conditions => {:type => PacketOperation::TYPES[:buy]}
  named_scope :sell,    :conditions => {:type => PacketOperation::TYPES[:sell]}
  named_scope :in_period, lambda {|period| {:conditions => ['DATE(created_at) BETWEEN ? AND ?', period.first_date, period.last_date]} }
  named_scope :before_operation,  lambda{|operation_number| {:conditions => ["number <= ?", operation_number]}}
  named_scope :after_operation,   lambda{|operation_number| {:conditions => ["number > ?", operation_number]}}
  named_scope :on_date,  lambda{|date| {:conditions => ["DATE(created_at) = ?", date.to_s(:db)]}}

  can_search do
    scoped_by :s_date, :attribute => :created_at, :scope => :sort, :alias => 'date'
    scoped_by :s_type, :attribute => :type,       :scope => :sort, :alias => 'type'
    scoped_by :s_amount, :attribute => 'ABS(amount)',   :scope => :sort, :alias => 'amount'
    scoped_by :s_quantity, :attribute => 'ABS(quantity)', :scope => :sort, :alias => 'quantity'
    scoped_by :s_tool_price, :attribute => :tool_price, :scope => :sort, :alias => 'price'

    scoped_by :date, :attribute => :created_at,  :scope => :date
    scoped_by :period, :attribute => :created_at, :scope => :date_range
    scoped_by :tool, :through => 'Portfolio::Packet', :through_attribute => 'packet_id'
    scoped_by :type
  end


  def portfolio_with_proxy
    portfolio_proxy || portfolio_without_proxy
  end
  alias_method_chain :portfolio, :proxy

  def amount_abs
    self.amount.abs
  end

  private
  def create_opposite_operation_before_destroy
    self.portfolio.do_in_operation(self) do
      @opposite = self.create_opposite_operation
    end
  end

  def delete_opposite_operation
    Portfolio::Operation.delete(@opposite)
  end

  def recalc_operation_numbers_after_destroy
    self.portfolio.do_in_operation(self) do
      self.portfolio.operations_after.update_all("number = number - 2")
    end
  end

  def recalc_operation_numbers
    self.portfolio.operations_after.update_all("number = number + 1", nil, :order => "number DESC")
  end

  def is_first_operation?
    self.number == 1
  end

  def kill_cache
    self.portfolio_proxy.try(:kill_cache)
  end
end

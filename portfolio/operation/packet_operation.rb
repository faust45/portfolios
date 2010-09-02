class Portfolio::Operation::PacketOperation < Portfolio::Operation
  #Abstract class
  include Portfolio::CustomValidations::Packet

  TYPES = { :buy => 'Portfolio::Operation::Buy', :sell => 'Portfolio::Operation::Sell' }

  set_table_name 'portfolio_operations'

  attr_accessor :packet_proxy, :money

  belongs_to :packet, :class_name => 'Portfolio::Packet'

  #assign_tool_price implement in child class
  before_validation :assign_current_tool_price, :if => :for_real_portfolio_if_blank?
  before_validation :assign_current_tool_price, :if => :for_training_portfolio_in_present_if_blank?
  before_validation :assign_quantity, :unless => :quantity?
  before_validation :assign_packet_id

  validate :exchange_is_working, :if => :for_real_portfolio?
  validate :was_exchange_working_day, :if => :in_past?
  validates_presence_of     :quantity, :message => 'quantity_required:Укажите количество.', :unless => :break?
  validates_numericality_of :quantity, :message => 'quantity_invalid:Количество в неверном формате.', :unless => :break?
  validates_numericality_of :quantity, :only_integer => true, :message => 'quantity_integer_required:Количество должно быть целым числом.', :unless => :break?
  validates_numericality_of :quantity, :greater_than => 0, :message => 'quantity_is_zero:Колличество должно быть больше нуля.', :unless => :break?
  validates_presence_of     :packet_id, :message => 'packet_required'
  validates_presence_of_tool_price
  validates_numericality_of :tool_price, :greater_than => 0, :message => 'tool_price_invalid:Не верная цена.', :unless => :break?

  before_create :assign_tool
  #только после валидаций quantity
  before_create :assign_amount
  before_create :add_sign_to_amount
  before_create :add_sign_to_quantity

  after_create  :recalc_portfolio_day_costs, :if => :for_training_portfolio_in_past?


  def with_cash?
    false
  end

  def with_tool?
    true
  end

  def calc_amount
    self.quantity * self.tool_price
  end

  def quantity_abs
    self.quantity.abs
  end

  def date
    self.created_at.to_date
  end

  private

  def assign_quantity
    if self.money && self.tool_price
      self.quantity = (self.money / self.tool_price).to_i
    end
  end

  def assign_amount
    self.amount = calc_amount
  end

  def assign_packet_id
    self.packet_id = self.packet_proxy.id
  end

  def assign_tool
    self.tool_id   = self.packet_proxy.tool_id
    self.tool_type = self.packet_proxy.tool_type
  end

  def assign_time
    unless self.created_at.today?
      work_to = self.packet_proxy.tool.exchange.work_to
      if work_to
        self.created_at = Time.parse(self.created_at.to_date.to_s + " #{work_to.hour}:#{work_to.min}")
      end
    end
  end

  #implements in concret class
  def add_sign_to_quantity
  end

  def add_sign_to_amount
  end

  def recalc_portfolio_day_costs
    operation_date = self.date.to_s(:db)

    connection.execute(<<-SQL)
      call portfolio_day_costs_recalc('#{operation_date}', #{self.portfolio_id}, #{self.tool_id}, #{self.quantity}, #{self.amount});
    SQL
  end
end

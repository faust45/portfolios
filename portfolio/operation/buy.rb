class Portfolio::Operation::Buy < Portfolio::Operation::PacketOperation

  validate :validate_insufficient_funds, :unless => :break?

  before_create :late_operations_not_break, :if => :in_past?, :unless => :break?

  after_create :update_packet_created_at


  def human_type
    'Покупка'
  end

  def money_out?
    true
  end

  protected
  def create_opposite_operation
    self.portfolio.sell(self.tool, self.quantity_abs, self.tool_price)
  end

  private
  def assign_current_tool_price
    self.tool_price = self.packet_proxy.tool.current_buy_price
  end

  def add_sign_to_amount
    self.amount *= -1
  end

  def update_packet_created_at
    if self.created_at.to_date < self.packet_proxy.created_at.to_date
      self.packet_proxy.update_attribute(:created_at, self.created_at)
    end
  end
end

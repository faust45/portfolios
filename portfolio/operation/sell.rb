class Portfolio::Operation::Sell < Portfolio::Operation::PacketOperation

  validate_available_quantity
  before_create  :validate_late_operations_not_break, :if => :in_past?, :unless => :break?


  def human_type
    'Продажа'
  end

  def money_out?
    false
  end


  protected
  def create_opposite_operation
    self.portfolio.buy(self.tool, self.quantity_abs, self.tool_price)
  end

  private
  def assign_current_tool_price
    self.tool_price = self.packet_proxy.tool.current_sell_price
  end

  def add_sign_to_quantity
    self.quantity *= -1
  end

  def validate_late_operations_not_break
    size = packet_proxy.size + self.quantity

    packet_proxy.operations_after_all.each do |op|
      size += op.quantity
      if size < 0
        raise Portfolio::BreakLateOperations.new(op)
      end
    end
  end
end

class Portfolio::StopOrder::Buy < Portfolio::StopOrder

  def apply!(quotes)
    self.portfolio.buy(self.tool, {:quantity => self.quantity, :money => self.money, :tool_price => quotes.offer})
    self.mark_as_completed
  end

  def can_apply?(quotes)
    quotes.offer <= self.stop_price
  end

  def stop_price_condition
    'offer <= :stop_price'
  end

  def close_condition
    'close <= ?'
  end

  def human_type
    'На покупку'
  end
end

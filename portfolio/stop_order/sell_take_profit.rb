class Portfolio::StopOrder::SellTakeProfit < Portfolio::StopOrder
  include Portfolio::StopOrder::Sell

  def can_apply?(quotes)
    quotes.bid >= self.stop_price
  end

  def stop_price_condition
    'bid >= :stop_price'
  end

  def close_condition
    'close >= ?'
  end

  def condition; '>=' end

  def human_type
    'На продажу (take-profit)'
  end
end


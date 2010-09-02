class Portfolio::StopOrder::SellStopLoss < Portfolio::StopOrder
  include Portfolio::StopOrder::Sell

  def can_apply?(quotes)
    quotes.bid <= self.stop_price
  end

  def stop_price_condition
    'bid <= :stop_price'
  end

  def close_condition
    'close <= ?'
  end

  def condition; '<=' end

  def human_type
    'На продажу (stop-loss)'
  end
end

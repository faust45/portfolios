module Portfolio::StopOrder::Sell
  def apply!(quotes)
    self.portfolio.sell(tool, { :quantity => quantity, :money => money, :tool_price => quotes.bid })
    self.mark_as_completed
  end
end


module Portfolio::Extensions::StopOrders
  def create(params)
    params = params.symbolize_keys

    tool = Share.find_by_id(params[:tool_id].to_i)
    params = params.merge(:tool => tool)

    order =
      case params[:type]
        when 'sell_take_profit'
          Portfolio::StopOrder::SellTakeProfit.new(params)
        when 'sell_stop_loss'
          Portfolio::StopOrder::SellStopLoss.new(params)
        when 'buy'
          Portfolio::StopOrder::Buy.new(params)
        else
          self.build(params)
      end

    self << order
    order
  end

  def create!(params)
    order = create(params)

    if order.break?
      raise Portfolio::StopOrderInvalid.new(order)
    end

    order
  end
end

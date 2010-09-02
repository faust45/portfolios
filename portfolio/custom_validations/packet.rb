module Portfolio::CustomValidations::Packet
  def self.included(klass)
    klass.extend ClassMethods
  end

  module ClassMethods
    def validates_presence_of_tool_price
      validate do |operation|
        unless operation.break?
          if operation.tool_price.blank?
            if operation.for_real_portfolio?
              operation.errors.add_to_base('tool_not_trade_today:Сегодня акция не торговалась.')
            else
              operation.errors.add_to_base('price_required:Укажите цену.')
            end
          end
        end
      end
    end

    def validate_available_quantity
      validate do |operation|
        unless operation.break?
          if operation.packet_proxy.size < operation.quantity
            operation.errors.add_to_base('tool_quantity_is_not_available:Вы не располагаете таким количеством акций.')
          end
        end
      end
    end
  end

  def exchange_is_working
    exchange = self.packet_proxy.tool.exchange

    unless exchange.real_working?(self.created_at)
      raise Exchange::NotWorking.new(self.created_at, exchange)
    end
  end

  def was_exchange_working_day
    exchange = self.packet_proxy.tool.exchange
    unless exchange.was_working_day?(self.created_at.to_date)
      raise Exchange::NotWorking.new(self.created_at, exchange)
    end
  end
end

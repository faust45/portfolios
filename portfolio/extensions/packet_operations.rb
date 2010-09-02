module Portfolio::Extensions::PacketOperations
  SORT_FIELDS = [:size, :cost, :portion, :profit, :tool_price, :change]
  SORT_FUN = {
    :tool_price => proc{|packet| packet.last_close_price.to_f },
    :change     => proc{|packet| packet.change_price.to_f },
    :portion    => :cost
  }


  def sorted(params)
    orders = @owner.packets_all

    if orders.any?
      field = params[:order]
      sort  = params[:sort]

      unless field.blank?
        field = field.to_sym

        if SORT_FIELDS.include?(field)
          fun = SORT_FUN[field] || field

          orders.sort! do |a, b|
            fun.to_proc.call(a) <=> fun.to_proc.call(b)
          end

          if sort.to_s == '1'
            orders.reverse!
          end
        end
      end
    end

    orders
  end

  def find_by_symbol(symbol)
    share = Share.find_by_symbol(symbol)

    if share
      self.first(:conditions => {:tool_type => share.class.to_s, :tool_id => share.id})
    end
  end

  def profit(date = nil)
    @owner.packets_all.inject(0) {|sum, packet|
      sum + packet.profit
    }
  end

  #Необходим reload portfolio.packets.cost на разные даты, т. к. packets запоминается.
  def cost
    @owner.packets_all.inject(0) do |total_cost, packet|
      total_cost + packet.cost
    end
  end

  def buy(tool, *args)
    Portfolio::Operation::PacketOperation.transaction do
      packet_with(tool).buy(*args)
    end
  end

  def sell(tool, *args)
    Portfolio::Operation::PacketOperation.transaction do
      packet_with(tool).sell(*args)
    end
  end

  def operations
    @owner.operations.packets
  end

  def packet_with(tool)
    # Достаём пакет (в любом случае даже если на дату контекста нет неодной операции), в тоже время агрегируем данные на дату контекста
    self.find_absolute(:first, :conditions => {:tool_type => tool.class.to_s, :tool_id => tool.try(:id)}) || self.create!(:tool => tool)

  rescue ActiveRecord::RecordInvalid => ex
    raise Portfolio::PacketInvalid.new(ex.record)
  end
end

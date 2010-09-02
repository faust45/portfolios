module Portfolio::Extensions::LoadPackets
  def all
    with_scope(:find => join_options) do
      custom_find(:all) 
    end
  end

  def find_absolute(*args)
    with_scope(:find => join_options(true)) do
      custom_find(*args)
    end
  end

  def custom_find(*args)
    with_scope(:find => custom_load_scopes) do
      add_portfolio_proxy(find(*args))
    end
  end

  private
  def custom_load_scopes
    { :select => "portfolio_packets.*, sum(portfolio_operations.amount) As operations_amount, sum(portfolio_operations.quantity) As size",
      :group  => "portfolio_packets.id" }
  end

  def join_options(absolute = false)
    join_type = absolute ? 'LEFT JOIN' : 'INNER JOIN'
    join_on   = ['portfolio_operations.packet_id = portfolio_packets.id']

    if @owner.in_point.in_past?
      join_on << @owner.in_point.join_on_conditions
    end

    { :joins  => "#{join_type} portfolio_operations ON(#{join_on.join(' AND ')})" }
  end

  def add_portfolio_proxy(records)
    Array(records).each do |p| 
      p.portfolio_proxy = @owner
    end

    records
  end
end

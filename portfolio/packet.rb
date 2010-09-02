class Portfolio::Packet < ActiveRecord::Base
  attr_accessor :portfolio_proxy
  delegate :in_date, :in_past?, :in_present?, :to => :portfolio_proxy

  belongs_to :tool, :polymorphic => true
  has_many :packet_operations, :class_name => 'Portfolio::Operation'

  validates_presence_of :tool_id, :message => 'tool_required'
  validates_presence_of :portfolio_id


  def buy(*args)
    portfolio_proxy.operations_raw.create_buy!(prepare_params(*args))
  end

  def sell(*args)
    portfolio_proxy.operations_raw.create_sell!(prepare_params(*args))
  end

  def is_sold?
    self.size == 0
  end

  def profit
    self.cost + operations_amount
  end

  def cost
    price = last_close_price || 0.0
    size * price.to_f
  end

  def portion
    portfolio_cost = self.portfolio_proxy.cost
    portfolio_cost == 0.0 ? portfolio_cost : self.cost / portfolio_cost

  rescue Portfolio::CostIsAbsent => ex
    nil
  end

  def size
    self[:size].to_i
  end

  def load_size
    operations.sum(:quantity)
  end

  def operations_amount
    self[:operations_amount].to_f
  end

  def last_close_price
    last_quotes.try(:close)
  end

  def change_price
    if last_quotes && last_quotes.date == self.in_date
      last_quotes.change
    end
  end

  def operations
    if portfolio_proxy
      portfolio_proxy.operations.scoped(:conditions => {:packet_id => self.id})
    else
      packet_operations
    end
  end

  def operations_after_all
    portfolio_proxy.operations_after.scoped(:conditions => {:packet_id => self.id})
  end

  private
  def prepare_params(*args)
    params =
      if args.first.is_a?(Hash)
        args.first
      else
        quantity, tool_price = args
        {:quantity => quantity, :tool_price => tool_price}
      end

    params.merge(:packet_proxy => self, :packet_id => self.id)
  end

  def last_quotes
    if self.in_past?
      self.tool.quote_days.last_quotes_before_date(self.in_date)
    else
      self.tool.quote_days_recent
    end
  end

  memoize :last_quotes
end

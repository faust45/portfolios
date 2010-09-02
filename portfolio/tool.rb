class Portfolio::Tool

  def initialize(tool, price_column = nil)
    @tool, @price_column = tool, price_column
  end

  def self.search(params, ar_options = {})
    price_column = PriceColumn.new(params)
    
    ar_options[:select] ||= "*, shares.symbol, q.#{price_column} As price, shares.id As id"
    ar_options[:joins]  ||= "left join quote_days As q ON(shares.id = q.share_id AND q.date = '#{price_column.date.to_s(:db)}')"

    # HACK: except_platform (RTS_CLASSICA в $, а мы с долларами пока не работаем)
    Share.live.except_platforms(ExchangePlatform::RTS_CLASSICA).
      search(params, ar_options).
      map{ |s| s.to_portfolio_tool(price_column) }
  end

  def self.find_by_id!(tool_id, params)
    raise Required.new if tool_id.blank?

    self.search(params.merge(:id => tool_id )).first || (raise NotFound.new)
  end

  def price
    @price ||= Price.new(super, @price_column)
  end

  def last_price
    last_quotes.try(:close)
  end

  def last_price_date
    last_quotes.try(:date)
  end

  def id
    @tool.id
  end

  def method_missing(sym, *args, &block)
    @tool.__send__(sym, *args, &block)
  end

  private
  def last_quotes
    @last_quotes ||= self.quote_days.last_quotes_before_date(price.date)
  end


  class Price
    attr_accessor :price, :price_column

    delegate :date, :type, :to => :price_column 
    delegate :blank?, :to_f, :to_s, :to => :price

    def initialize(price, price_column)
      @price, @price_column = price, price_column
    end
  end


  class PriceColumn
    BUY_PRICE  = 'offer'
    SELL_PRICE = 'bid'

    attr_reader :date, :operation_type 
    alias :type :operation_type

    def initialize(params)
      @date = params[:date].blank? ? Date.today : CustomDate.parse!(params[:date])
      @operation_type = params[:operation_type].to_s
    end

    def column_name
      if date.today?
        case operation_type
          when 'buy':  BUY_PRICE
          when 'sell': SELL_PRICE
          else BUY_PRICE
        end
      else
        'close'
      end
    end

    def to_s
      column_name
    end
  end

  class NotFound < Portfolio::PortfolioException
  end

  class Required < Portfolio::PortfolioException
  end

  class NotTrade < Portfolio::PortfolioException

    def initialize(tool, portfolio)
      if portfolio.training?
        if tool.last_price
          @code = "#{class_name_to_code}_training_portfolio"

          super(nil, :date_requested   => tool.price.date.to_s(:ru),
                     :close_price      => tool.last_price,
                     :close_price_date => tool.last_price_date.to_s(:ru))
        else
          @code = "no_data_before_date"
          super(nil, :date => tool.price.date.to_s(:ru))
        end
      else
        @code = "#{class_name_to_code}_real_portfolio_#{tool.price.type}"
      end
    end
  end
end

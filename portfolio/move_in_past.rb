module Portfolio::MoveInPast
  def self.included(klass)
    klass.send(:delegate, :operations_raw, :operations, :operations_after, :in_date, :in_past?, :in_present?,
               :to => :in_point)
  end

  def in_month
    Month.new(in_date)
  end

  def in_point
    move_in_present unless @in_point
    @in_point
  end

  def move_in_operation(operation)
    @in_point = operation_point(operation)
    self
  end

  def move_in_past(date_in_past)
    unless date_in_past.nil?
      date_in_past = date_in_past.to_date

      if date_in_past.today?
        move_in_present
      else
        @in_point = date_point(date_in_past)
      end
    end

    self
  end

  def move_in_month(month)
    date = month.end_date

    do_in_present do
      if live_period.last_month == month
        date = live_period.last_date
      end
    end

    move_in_past(date)
  end

  def move_in_present
    if in_archive?
      move_in_past(to_archive_date - 1.day)
    else
      @in_point = present_point
    end

    self
  end

  def do_in_date(date)
    @save_in_point = @in_point
    move_in_past(date)

    begin
      value = yield
    ensure
      @in_point = @save_in_point
    end

    value
  end

  def do_in_operation(operation)
    @save_in_point = @in_point
    move_in_operation(operation)

    begin
      value = yield
    ensure
      @in_point = @save_in_point
    end

    value
  end

  def do_in_present(&block)
    do_in_date(Date.today, &block)
  end
end


module CacheBehaviour
  def self.included(klass)
    klass.extend ClassMethods
    klass.cache_on_point :first_operation, :packets_all, :operations_all, :operations_after_all
    klass.send(:attr_reader, :cache, :points_cache)
  end

  def first_operation;      operations.first     end
  def packets_all;          packets.all          end
  def operations_all;       operations.all       end
  def operations_after_all; operations_after.all end

  def kill_cache
    @cache, @points_cache, @cost_cache = nil, nil, nil
    @in_point.retrive
  end

  module ClassMethods
    def cache_on_point(*methods)
      methods.each do |method|
        self.send :define_method, "#{method}_with_cache_behaviour" do |*args|
          @cache ||= {}
          @cache[self.in_point] ||= {}
          @cache[self.in_point][method.to_s + args.hash.to_s] ||= send("#{method}_without_cache_behaviour", *args)
        end

        self.alias_method_chain method, :cache_behaviour
      end
    end
  end
end

module Portfolio::Extensions::CalcDayCosts
  def recalc
    self.delete_all 
    calc_missed_days
  end

  def calc_missed_days
    last_date_with_cost = self.last_date_with_cost

    start_date =
      if last_date_with_cost
        last_date_with_cost + 1.day
      else
        @owner.live_period.first_date
      end


    unless start_date.nil?
      end_date = exchange_closed? ? Date.today : 1.day.ago.to_date

      working_days = Exchange.working_days(start_date .. end_date)

      prev_cost =
        if last_date_with_cost 
          on_date(last_date_with_cost)
        else
          0
        end

      (start_date .. end_date).inject(prev_cost) do |prev_cost, date|
        is_working_day = working_days.include?(date)
        @owner.move_in_past(date)
        cost = is_working_day ? @owner.calculate_cost : prev_cost

        self.create!(:date => date, :is_working_day => is_working_day, :cost => cost)
        cost
      end
    end
  end

  def on_date(date)
    self.first(:conditions => {:date => date.to_date}).try(:cost)
  end

  def last_date_with_cost
    last = self.desc('date').first
    last.try(:date)
  end

  def exchange_closed?
    Exchange.all.find(&:real_working?) ? true : false
  end
end

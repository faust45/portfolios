module Portfolio::Extensions::RatingList
  def create!
    super(:month         => @owner.in_month,
          :created_at    => @owner.in_date,
          :raw_rating    => calc_rating,
          :profitability => @owner.profitability_in_yearly,
          :rating        => nil,
          :position      => nil)
  end

  def rating
    current_rating.rating
  end

  def position
    current_rating.position
  end

  def profitability
    current_rating.profitability
  end

  private
  def calc_rating
    profitability = @owner.profitability_in_yearly

    !profitability.blank? ? Math.tanh((@owner.age / 1.day) / 30.0) * profitability : 0
  end

  def current_rating
    self.search.first || build
  end
end

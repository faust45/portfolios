class Portfolio::RatingList < ActiveRecord::Base
  include Comparable

  set_table_name 'portfolio_rating_list'

  belongs_to :portfolio

  composed_of :month, :class_name => 'Month',
                      :mapping => %w(date first_date),
                      :converter => :parse

  can_search do
    scoped_by :month, :scope => :composed,
                      :default_scope_by => lambda{ Month.new( Portfolio::RatingList.maximum(:date) ) }
  end


  def self.top_up(num = 5)
    self.asc(:position).limit(num).search({}, :include => {:portfolio => :user})
  end

  def self.top_down(num = 5)
    self.desc(:position).limit(num).search({}, :include => {:portfolio => :user})
  end

  def self.proccess(on_month = nil)
    RealPortfolio.public.active.age_gt(1.day).find_each(:batch_size => 100) do |portfolio|
      first_month = on_month || portfolio.live_period.first_month
      last_month  = portfolio.live_period.last_month

      period = (first_month..last_month).to_a

      period.each do |month|
        portfolio.move_in_month(month)

        if portfolio.age >= 1.day
          unless portfolio.profitability.blank?
            portfolio.rating_list.create!
          end
        end
      end
    end

    months = Portfolio::RatingList.all(:group => :date).map(&:month)
    months.reverse.each do |month|
      self.normalize_on_month(month)
    end
  end

  def <=>(other)
    self.to_f <=> other.to_f
  end

  def to_f
    self.rating.to_f
  end

  private
  def self.normalize_on_month(month)
    ratings = self.by_month(month).asc(:raw_rating).find_attrs(:raw_rating)

    min_rating = ratings.first.to_f
    max_rating = ratings.last.to_f
    delta = max_rating - min_rating

    position = 1
    self.by_month(month).desc(:raw_rating).all.inject(0.0) do |prev_normalize_rating, rating|
      if delta == 0.0
        normalize_rating = 0.0
      else
        normalize_rating = (rating.raw_rating - min_rating) / delta
      end

      rating.rating = normalize_rating
      position += 1 if normalize_rating < prev_normalize_rating
      rating.position = position
      rating.save

      normalize_rating
    end
  end
end

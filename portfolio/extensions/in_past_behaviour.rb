module Portfolio::Extensions::InPastBehaviour
  def create(attributes = {}, &block)
    if @owner.in_past?
      raise 'Operations with RealPortfolio in past not permit.' if @owner.real?
      attributes = attributes.merge(:created_at => @owner.date_in_past)
    end

    super(attributes, &block) 
  end
end

class RealPortfolio < Portfolio
  LABELS = superclass::LABELS

  can_search do
    scoped_by :date, :attribute => 'created_at', :scope => :date
  end


  def operations_allow? 
    !archive? && in_present? ? true : false
  end

  def human_type
    'рыночный'
  end

  def real?
    true
  end

  def training?
    false
  end
end


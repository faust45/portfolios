class TrainingPortfolio < Portfolio
  include Portfolio::CustomValidations::DateValidations
  LABELS = superclass::LABELS

  attr_accessible :name, :access_type, :archive, :created_at

  validate_date_format(:created_at) 
  validate_date_in_period(:created_at, :msg_in_past => 'Дату создания портфеля можно указать начиная с 1 января 2000 года.',
                                       :msg_in_future => 'Нельзя указать дату создания портфеля в будущем.')


  def operations_allow? 
    !archive? ? true : false
  end

  def human_type
    'учётный'
  end

  def real?
    false 
  end

  def training?
    true 
  end

  def created_at
    first_operation_date || super
  end
end

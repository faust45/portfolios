class Portfolio::DayCost < ActiveRecord::Base
  date_scopes :date
  named_scope :only_working_days, :conditions => {:is_working_day => true} 
end

module Portfolio::Extensions::BeforeAddOperation
  def assign_portfolio_proxy(obj_to_add)
    obj_to_add.portfolio_proxy = self
  end

  def assign_date(obj_to_add)
    if self.in_past?
      obj_to_add.created_at =
        if self.in_date.today?
          self.in_point.last_operation.created_at
        else
          obj_to_add.created_at = self.in_date
        end
    end
  end

  def assign_number(obj_to_add)
    obj_to_add.number = self.in_point.to_i + 1
  end
end

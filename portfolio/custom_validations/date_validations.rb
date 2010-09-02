module Portfolio::CustomValidations::DateValidations
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def validate_date_format(field_name, options = {})
      validate do |record|
        cond = true

        if options[:if]
          method = options[:if]
          cond = record.send(method)
        end

        if cond
          date = record.send(field_name.to_s + '_before_type_cast')

          unless date.blank?
            if date.is_a?(String)
              unless CustomDate.valid_format?(date)
                record.errors.add_to_base(field_name.to_s + '_invalid:Неверный формат даты.')
              end
            end
          end
        end
      end
    end

    def validate_date_in_period(field_name, options = {})
      validate do |record|
        date = record.send(field_name.to_s + '_before_type_cast')

        unless date.blank?
          unless record.break?
            min_date = '1 Jan 2000'.to_date
            date = date.to_custom_date 

            if date < min_date
              record.errors.add_to_base("date_must_be_after:#{options[:msg_in_past]}")
            end

            if Time.now < date
              record.errors.add_to_base("operations_in_future_not_allow:#{options[:msg_in_future]}")
            end
          end
        end
      end
    end
  end
end

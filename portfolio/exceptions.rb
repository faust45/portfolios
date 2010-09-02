module Portfolio::Exceptions
  class PortfolioException < JsonException; end
  class OperationException < PortfolioException; end

  class CostIsAbsent < StandardError; end

  class OperationInvalid < OperationException
    attr_accessor :operation

    def initialize(operation)
      @operation = operation
    end

    def to_json(*args)
      custom_errors =
        @operation.errors.map do |_, value|
          if value.is_a?(Hash)
            code = value.keys.first
            data = value.values.first
          else
            code = value
          end

        {:code => code, :data => data}
      end

      {:errors => custom_errors}.to_json
    end
  end

  class PacketInvalid < OperationInvalid; end

  class BreakLateOperations < OperationException
    CODE = 'break_late_operations'
    attr_accessor :break_operation

    def initialize(break_operation)
      @break_operation = break_operation
    end
  end

  class InsufficientFunds < OperationException
    CODE = 'insufficient_funds'
    DESC = 'Недостаточно средств.'
  end

  class CannotOperateWithArchivePortfolio < OperationException
    CODE = 'cannot_operate_with_archive_portfolio'
    DESC = 'Невозможно совершать операции с архивным портфелем'
  end

  class StopOrderInvalid < OperationInvalid; end
  class StopOrderBreakLateOperations < BreakLateOperations
    CODE = 'stop_order_break_late_operations'
  end
end

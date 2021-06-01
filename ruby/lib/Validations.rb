module ORM
  class Validation
    def validate value
      if condition value then
        raise ORM_Error.new(error)
      end
    end
  end

  class ValidationNoBlank < Validation
    def initialize needs_validation
      @needs_validation = needs_validation
    end

    def condition value
      @needs_validation and (value.nil? || value.empty?)
    end

    def error
      'The instance can not be nil nor empty'
    end
  end

  class ValidationByBlock < Validation
    def initialize block
      @block = block
    end

    def condition value
      !value.instance_eval(&@block)
    end

    def error
      'The instance has invalid values'
    end
  end

  class ValidationTo < Validation
    def initialize max
      @max = max
    end

    def condition value
      value > @max
    end

    def error
      'The instance can not be bigger than the maximum required'
    end
  end

  class ValidationFrom < Validation
    def initialize min
      @min = min
    end

    def condition value
      value < @min
    end

    def error
      'The instance can not be smaller than the minimum required'
    end
  end

end

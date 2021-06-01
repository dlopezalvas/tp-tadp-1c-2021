module Restrictions

  def self.validateRestrictions type, description
    validateNumeric type, description
    validateLimits description
    validateDefaultType type, description
  end

  def self.validateNumeric type, description
    raise ORM::ORM_Error.new("A #{type} cant have to: or from: restrictions") if (not type <= Numeric) && (description[:to] or description[:from]) #el type <= es un ancestors.include? Numeric
  end

  def self.validateLimits description
    raise ORM::ORM_Error.new("to: limit cant be lower than from: limit") if description[:to] and description[:from] and description[:from] > description[:to]
  end

  def self.validateDefaultType type, description
    raise ORM::ORM_Error.new("Default value must a #{type}") if (description[:default] and not description[:default].is_a? type)
  end

end
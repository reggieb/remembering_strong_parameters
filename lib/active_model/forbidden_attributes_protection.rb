module ActiveModel
  class ForbiddenAttributes < StandardError
  end

  module ForbiddenAttributesProtection
    def sanitize_for_mass_assignment(*options)
      new_attributes = options.first
      if !new_attributes.respond_to?(:strengthened?) || new_attributes.strengthened?
        super
      else
        raise ActiveModel::ForbiddenAttributes
      end
    end
  end
end

ActiveModel.autoload :ForbiddenAttributesProtection

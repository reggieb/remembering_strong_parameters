require 'active_support/concern'
require 'active_support/core_ext/hash/indifferent_access'
require 'action_controller'

module ActionController
  class ParameterMissing < IndexError
    attr_reader :param

    def initialize(param)
      @param = param
      super("key not found: #{param}")
    end
  end

  class Parameters < ActiveSupport::HashWithIndifferentAccess
    
    REQUIRED_FLAGS = [:required, :require]
    PERMITTED_FLAGS = [:permitted, :permit] + REQUIRED_FLAGS
    
    def strengthened?
      @strengthened
    end
    alias :permitted? :strengthened?
    

    def initialize(attributes = nil)
      super(attributes)
    end

    def permit!
      replace to_check
      @strengthened = true
      each_pair do |key, value|
        convert_hashes_to_parameters(key, value)
        self[key].permit! if self[key].respond_to? :permit!
      end
      
      self
    end
    
    def strengthen(filter = {})
      return unless filter.kind_of? Hash
      
      filter = filter.with_indifferent_access
      
      if keys_all_numbers?
        strengthen_numbered_hash_as_array(filter)
      else
        strengthen_hash(filter)
      end
       
    end
    
    def require(key)
      strengthen(key => REQUIRED_FLAGS.first)
      to_check[key].presence
    end

    def permit(*filters)
      strengthen(hash_from(filters, PERMITTED_FLAGS.first))
    end
    
    def original
      to_check
    end
    
    def [](key)
      convert_hashes_to_parameters(key, super)
    end

    def fetch(key, *args)
      convert_hashes_to_parameters(key, super)
    rescue KeyError, IndexError
      raise ActionController::ParameterMissing.new(key)
    end

    def slice(*keys)
      self.class.new(super).tap do |new_instance|
        copy_instance_variables_to new_instance
      end
    end

    def dup
      self.class.new(self).tap do |duplicate|
        duplicate.default = default
        copy_instance_variables_to duplicate
      end
    end
    
    def check_required(filter)
      if filter.kind_of? Hash
        filter.each do |key, value|
          flag_error_if_abscent(key) if required_flag?(value) or value.kind_of? Hash
          to_check[key].check_required(value) if value.respond_to? :check_required and to_check.has_key? key
        end
      end
      unless missing_required_fields.empty?
        raise ActionController::ParameterMissing.new("'#{missing_required_fields.join("', '")}' required by #{filter}")
      end
    end 

    protected
      def convert_value(value)
        if value.class == Hash
          self.class.new_from_hash_copying_default(value)
        elsif value.is_a?(Array)
          StrongArray.new(value).replace(value.map { |e| convert_value(e) })
        else
          value
        end
      end
      
      def each_element(object)
        if object.is_a?(Array)
          object = StrongArray.new(object)
          object.map { |el| yield el }.compact
        # fields_for on an array of records uses numeric hash keys
        elsif object.is_a?(Hash) && object.keys.all? { |k| k =~ /\A-?\d+\z/ }
          hash = object.class.new
          object.each { |k,v| hash[k] = yield v }
          hash
        else
          yield object
        end
      end
      
      def been_checked
        @been_checked ||= self.class.new
      end

      def to_check
        @to_check ||= clone
      end     

    private
      def hash_from(array, value)
        array = [array] unless array.kind_of? Array
        array.collect! do |a| 
          if a.kind_of?(Hash)
            key = a.keys.first
            [key, hash_from(a[key], value)]
          else
            [a, value]
          end  
        end
        Hash[array]
      end
      
      def keys_all_numbers?
        /^[\-\d]+$/ =~ to_check.keys.join
      end

      def strengthen_numbered_hash_as_array(filter = {})
        strong_array = StrongArray.new(to_check.values)
        Hash[[to_check.keys.collect{|k| k.to_sym}, strong_array.strengthen(filter)].transpose]      
      end

      def strengthen_hash(filter = {})
        check_required(filter)

        to_check.each do |key, value|
          multiparameterless_key = key.gsub(/\(\d+[fi]?\)$/, "")

          if filter[multiparameterless_key]
            if value.respond_to?(:strengthen)
              stengthened_value = value.strengthen(filter[multiparameterless_key])
              been_checked[key] = stengthened_value if stengthened_value
            else
              check_key(key) if permitted_flag?(filter[multiparameterless_key])
            end
          end
        end

        @strengthened = true

        replace been_checked
      end
      
      
      def convert_hashes_to_parameters(key, value)
        if value.is_a?(Parameters) || !value.is_a?(Hash)
          value
        else
          # Convert to Parameters on first access
          self[key] = self.class.new(value)
        end
      end
      
      def missing_required_fields
        @missing_required_fields ||= []
      end

      def check_key(key)
        check_matching_key(key)
        check_matching_multi_parameter_keys(key)
      end

      def check_matching_key(key)
        been_checked[key] = to_check[key] if to_check.has_key?(key)
      end

      def check_matching_multi_parameter_keys(key)
        to_check.keys.grep(/\A#{Regexp.escape(key.to_s)}\(\d+[fi]?\)\z/).each { |key| been_checked[key] = to_check[key] }
      end
      
      def copy_instance_variables_to(other_instance)
        other_instance.instance_variable_set :@to_check, @to_check
        other_instance.instance_variable_set :@been_checked, @been_checked
        other_instance.instance_variable_set :@strengthened, @strengthened
      end
      
      def flag_error_if_abscent(key)
        if !to_check.has_key? key
          missing_required_fields << key 
        elsif to_check[key].kind_of? Hash and to_check[key].empty?
          missing_required_fields << key
        end
      end

      def required_flag?(value)
        value.respond_to? :to_sym and REQUIRED_FLAGS.include?(value.to_sym)
      end
      
      def permitted_flag?(value)
        value.respond_to? :to_sym and PERMITTED_FLAGS.include?(value.to_sym)
      end
      
  end

  module RememberingStrongParameters
    extend ActiveSupport::Concern

    included do
      rescue_from(ActionController::ParameterMissing) do |parameter_missing_exception|
        render :text => "Required parameter missing: #{parameter_missing_exception.param}", :status => :bad_request
      end
    end

    def params
      @_params ||= Parameters.new(request.parameters)
    end

    def params=(val)
      @_params = val.is_a?(Hash) ? Parameters.new(val) : val
    end
  end
  
  class StrongArray < Array
    
    def strengthen(filter = {})
      original.each do |element|
        case element
        when Hash
          element = ActionController::Parameters.new element
        when Array
          element = self.class.new element  
        end
        
        if element.respond_to? :strengthen
          been_checked << element.strengthen(filter)
        else
          been_checked << element if Parameters::PERMITTED_FLAGS.include?(filter)
        end
      end

      @strengthened = true
      been_checked
    end
    
    def been_checked
      @been_checked ||= self.class.new
    end
    
    def original
      @original ||= self.clone
    end
    
    def strengthened?
      @strengthened
    end
    alias :permitted? :strengthened?
    
    
    def check_required(filter = {})
      each{|e| e.check_required(filter) if e.respond_to? :check_required}
    end

  end
end

ActionController::Base.send :include, ActionController::RememberingStrongParameters

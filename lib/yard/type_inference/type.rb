module YARD::TypeInference
  class Type
    def initialize(*args)

    end

    def path
      raise NotImplementedError
    end

    def ==(o)
      o.is_a?(Type) && o.path == self.path
    end

    class << self
      def from_object(obj)
        if obj.is_a?(YARD::CodeObjects::ClassObject)
          ClassType.new(obj)
        elsif obj.is_a?(YARD::CodeObjects::MethodObject)
          MethodType.new(obj.namespace, obj.scope, obj.name, obj)
        else
          raise ArgumentError, "invalid obj: #{obj.inspect} (#{obj.type})"
        end
      end
    end
  end

  class ClassType < Type
    def initialize(klass)
      super
      if klass.is_a?(String)
        resolved = YARD::Registry.resolve(:root, klass, false, true)
        if resolved
          klass = resolved
        end
      end
      @klass = klass
    end

    attr_reader :klass

    def path
      if klass.is_a?(YARD::CodeObjects::Base) || klass.is_a?(YARD::CodeObjects::Proxy)
        klass.path
      else
        klass
      end
    end
  end

  class InstanceType < ClassType
    def path
      super + '#'
    end
  end

  class ArrayInstanceType < InstanceType
    def initialize(element_type = nil)
      @element_type = YARD::Registry.resolve(:root, element_type, false, true)
      super("::Array")
    end

    attr_reader :element_type

    def has_element_type?
      element_type and !element_type.path.empty?
    end
  end

  class HashInstanceType < InstanceType
    def initialize(value_type = nil)
      @value_type = YARD::Registry.resolve(:root, value_type, false, true)
      super("::Hash")
    end

    attr_reader :value_type

    def has_value_type?
      value_type and !value_type.path.empty?
    end
  end


  class MethodType < Type
    def initialize(namespace, method_scope, method_name, method_obj)
      @namespace = namespace
      @method_scope = method_scope
      @method_name = method_name
      @method_obj = method_obj
      @return_type = AbstractValue.new
    end

    attr_reader :namespace
    attr_reader :method_scope
    attr_reader :method_name
    attr_reader :method_obj

    attr_reader :return_type

    def check!
      return_type.types.each do |t|
        if t.is_a?(MethodType)
          raise "MethodType.return_type AbstractValue should not have MethodType types"
        end
      end
    end

    def path
      method_obj.path
    end
  end
end

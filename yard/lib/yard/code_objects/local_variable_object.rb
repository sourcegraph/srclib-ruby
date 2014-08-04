module YARD::CodeObjects
  # Represents a local variable inside a scope. The path is expressed
  # in the form TODO!(sqs)
  class LocalVariableObject < Base
    # Creates a new local variable object in +local_scope+ with +name+.
    #
    # @see Base.new
    def initialize(local_scope, name, *args, &block)
      @local_scope = local_scope
      super(local_scope, name, *args, &block)
    end

    # @return [String] the local variable's assigned value
    attr_accessor :rhs

    # @return [CodeObjects::Base] the object that creates this local variable's
    # enclosing scope
    attr_accessor :local_scope

    def name(prefix = false)
      prefix ? "#{sep}#{super}" : super
    end

    def sep
      ">"
    end
  end
end

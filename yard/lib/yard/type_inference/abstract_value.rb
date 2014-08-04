MAX_FORWARD = 10
MAX_DEPTH = 25

module YARD::TypeInference
  class AbstractValue
    attr_reader :types
    attr_accessor :constant

    def initialize
      @forward = []
      @types = []
      @constant = false
    end

    def add_type(type, _depth = 0)
      raise ArgumentError, "invalid type: #{type}" unless type.is_a?(Type) or type.is_a?(YARD::CodeObjects::Proxy)
      @types << type unless @types.include?(type)
      @forward[0..MAX_FORWARD-1].each do |fwd|
        add_type_to_abstract_value(type, fwd, _depth)
      end
    end

    def propagate(target)
      return if target == self
      # raise ArgumentError, "target is self: #{target.inspect} == #{self.inspect}" if target == self
      raise ArgumentError, "invalid target: #{target}" unless target.is_a?(AbstractValue)
      @forward << target unless @forward.include?(target)
      @types.each do |type|
        add_type_to_abstract_value(type, target)
      end
    end

    def lookup_method(method_name)
      @types.each do |type|
        if type.is_a?(ClassType) && type.klass.is_a?(YARD::CodeObjects::ClassObject)
          type.klass.meths.each do |mth|
            if mth.name.to_s == method_name
              return mth
            end
          end
        end
      end
      nil
    end

    def type_string()
      @types.map(&:path).join(', ')
    end

    def return_types
      @types.select { |t| t.is_a? MethodType }.map(&:return_type)
    end

    def type(guess = false)
      if types.length == 0
        nil
      elsif types.length == 1 or guess
        types[0]
      end
    end

    class << self
      def single_type(type)
        av = AbstractValue.new
        av.add_type(type)
        av.constant = true
        av
      end

      def single_type_nonconst(type)
        av = AbstractValue.new
        av.add_type(type)
        av
      end

      def nil_type
        single_type(InstanceType.new("::NilClass"))
      end
    end

    private

    def add_type_to_abstract_value(type, aval, _depth = 0)
      raise ArgumentError, "target is constant: #{aval.inspect}" if aval.constant
      if _depth > MAX_DEPTH
        @num_max_depth_errors ||= 0
        log.warn "add_type_to_abstract_value MAX_DEPTH exceeded (#{_depth}), not adding type" if @num_max_depth_errors < 3
        @num_max_depth_errors += 1
        return
      end
      aval.add_type(type, _depth + 1)
    end
  end
end

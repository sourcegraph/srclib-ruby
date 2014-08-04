module YARD::TypeInference
  class Expr
    attr_reader :expr_object
    attr_reader :scope
    attr_reader :abstract_value

    def initialize(expr_object, scope)
      @expr_object = expr_object
      @scope = scope
      @abstract_value = AbstractValue.new
    end
  end

  class ObjectExpr < Expr
    def initialize(object, scope)
      raise ArgumentError, "invalid object: #{object} (#{object.type})" unless object.is_a?(YARD::CodeObjects::Base) || object.is_a?(YARD::CodeObjects::Proxy)
      super(object, scope)
    end

    alias object expr_object
  end

  class AnonymousExpr < Expr
    def initialize(ast_node, scope)
      raise ArgumentError, "invalid ast_node: #{ast_node}" unless ast_node.is_a?(YARD::Parser::Ruby::AstNode) || ast_node.is_a?(YARD::Parser::C::ToplevelStatement)
      super(ast_node, scope)
    end

    alias ast_node expr_object
  end
end

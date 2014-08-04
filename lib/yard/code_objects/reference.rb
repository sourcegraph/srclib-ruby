module YARD::CodeObjects
  class Reference
    def initialize(target, ast_node, register = true, kind = "ident")
      raise ArgumentError, "invalid target type #{target.class}" unless target.is_a?(Base) || target.is_a?(Proxy)
      raise ArgumentError, "invalid AST node type" unless ast_node.is_a?(YARD::Parser::Ruby::AstNode)

      @target = target
      @ast_node = ast_node
      @kind = kind

      if register
        YARD::Registry.add_reference(self)
      end
    end

    # @return [CodeObjects::Base] the object that this reference points to
    attr_reader :target

    # @return [Parser::Ruby::AstNode] the AST node of the reference expression
    attr_reader :ast_node

    attr_reader :kind

    def ==(other)
      other.target == self.target && other.ast_node == ast_node && other.ast_node.source_range == self.ast_node.source_range && other.ast_node.file == self.ast_node.file && self.kind == other.kind
    end
  end
end

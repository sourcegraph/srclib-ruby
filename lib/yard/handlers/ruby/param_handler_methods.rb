# Helper methods for method and block parameters
module YARD::Handlers::Ruby::ParamHandlerMethods
  include YARD::CodeObjects

  def handle_params(params, body_scope)
    (params.required_params || []).each do |param|
      register LocalVariableObject.new(body_scope, param.source, param) do |o|
        o.source = param
        o.owner = namespace
      end
    end
    (params.optional_params || []).each do |param|
      register LocalVariableObject.new(body_scope, param[0].source, param) do |o|
        o.source = param
        o.rhs = param[1]
        o.owner = namespace
      end
    end
    if splat = params.splat_param and splat.is_a?(YARD::Parser::Ruby::AstNode)
      register LocalVariableObject.new(body_scope, splat.source, splat) do |o|
        o.source = splat
        o.owner = namespace
      end
    end
    if keyword = params.keyword_param
      register LocalVariableObject.new(body_scope, keyword.source, keyword) do |o|
        o.source = keyword
        o.owner = namespace
      end
    end
    if block = params.block_param
      register LocalVariableObject.new(body_scope, block.source, block) do |o|
        o.source = block
        o.owner = namespace
      end
    end
    (params.required_end_params || []).each do |param|
      register LocalVariableObject.new(body_scope, param.source, param) do |o|
        o.source = param
        o.owner = namespace
      end
    end
  end
end

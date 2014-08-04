# Handles a block
class YARD::Handlers::Ruby::BlockHandler < YARD::Handlers::Ruby::Base
  include YARD::Handlers::Ruby::ParamHandlerMethods

  handles :do_block, :brace_block

  process do
    body_scope = owner.new_local_scope("@block", local_scope)
    handle_params(statement[0][0], body_scope) if statement[0]
    parse_block(statement[1], :owner => owner, :namespace => namespace, :local_scope => body_scope)
  end
end

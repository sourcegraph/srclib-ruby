module YARD::TypeInference
  class Processor
    def initialize
      @started = {}
      @namespace = nil
      @memo = {}
    end

    def process_ast_list(ast)
      ast.select do |ast_node|
        ast_node.is_a?(YARD::Parser::Ruby::AstNode) && !ast_node.is_a?(YARD::Parser::Ruby::CommentNode)
      end.map do |ast_node|
        process_ast_node(ast_node)
      end.last if ast
    end

    alias process_list process_ast_list

    @@i = 0
    def process_ast_node(ast_node)
      if @@i % 500 == 0
        log.warn "Type inference: processing #{ast_node.type} at #{ast_node.file} line #{ast_node.line_range} (#{@@i} nodes seen)"
      end
      @@i += 1

      if ast_node.is_a?(YARD::Parser::C::ToplevelStatement)
        method_name = "process_C_toplevel"
      else
        method_name = "process_#{ast_node.type}"
      end

      if not respond_to?(method_name)
        raise ArgumentError, "no #{method_name} processor method - AST node is #{ast_node} at #{ast_node.file} line #{ast_node.line_range}"
      end

      ast_node_key = YARD::Registry._ast_key_with_type(ast_node)

      # handle circular refs
      if @started[ast_node_key] && !@memo.include?(ast_node_key)
        return YARD::Registry.abstract_value_for_ast_node(ast_node, false)
      end

      if @memo.include?(ast_node_key)
        return @memo[ast_node_key]
      end

      @started[ast_node_key] = true
      @memo[ast_node_key] = begin
                              send(method_name, ast_node)
                            rescue Exception => ex
                              log.warn "Type inference exception on AST node #{ast_node} at #{ast_node.file} line #{ast_node.line_range} (chars #{ast_node.source_range}), continuing"
                              if log.show_backtraces
                                log.warn ex.to_s
                                log.warn ex.backtrace.join("\n")
                              end
                              YARD::Registry.abstract_value(ast_node)
                            end
    end

    def process_assign(ast_node)
      lhs = ast_node[0]
      rhs = ast_node[1]
      rhs_av = process_ast_node(rhs)
      lhs_av = YARD::Registry.abstract_value(lhs)
      rhs_av.propagate(lhs_av)
      av = YARD::Registry.abstract_value_for_ast_node(ast_node, false)
      lhs_av.propagate(av)
      av
    end

    def process_massign(node)
      # TODO(sqs)
      YARD::Registry.abstract_value(node)
    end

    def process_aref(ast_node)
      node_av = process_ast_node(ast_node[0])
      if t = node_av.type and t.is_a?(ArrayInstanceType) and t.has_element_type?
        AbstractValue.single_type(t.element_type)
      elsif t = node_av.type and t.is_a?(HashInstanceType) and t.has_value_type?
        AbstractValue.single_type(t.value_type)
      else
        YARD::Registry.abstract_value(ast_node)
      end
    end

    def process_class(ast_node)
      object = YARD::Registry.get_object_for_ast_node(ast_node)
      if object
        outer = @namespace
        @namespace = object
      end

      bodystmt = ast_node[2]
      process_ast_node(bodystmt)

      if object
        @namespace = outer
      end

      nil
    end

    def process_sclass(ast_node)
      object = YARD::Registry.get_object_for_ast_node(ast_node)
      if object
        outer = @namespace
        @namespace = object
      end

      bodystmt = ast_node[1]
      process_ast_node(bodystmt)

      if object
        @namespace = outer
      end

      nil
    end

    def process_module(ast_node)
      object = YARD::Registry.get_object_for_ast_node(ast_node)
      if object
        outer = @namespace
        @namespace = object
      end

      bodystmt = ast_node[1]
      process_ast_node(bodystmt)

      if object
        @namespace = outer
      end

      nil
    end

    def process_def(ast_node)
      method_obj = YARD::Registry.get_object_for_ast_node(ast_node)
      return YARD::Registry.abstract_value(ast_node) if !method_obj

      method_type = Type.from_object(method_obj)

      body_av = process_ast_node(ast_node[2]) # def body
      if body_av
        body_av.propagate(method_type.return_type)
      end

      def_av = YARD::Registry.abstract_value_for_ast_node(ast_node, false)
      AbstractValue.single_type_nonconst(method_type).propagate(def_av)
      def_av
    end

    def process_defs(ast_node)
      method_obj = YARD::Registry.get_object_for_ast_node(ast_node)
      return YARD::Registry.abstract_value(ast_node) if !method_obj

      method_type = Type.from_object(method_obj)

      body_av = process_ast_node(ast_node[4]) # def body
      if body_av
        body_av.propagate(method_type.return_type)
      end

      def_av = YARD::Registry.abstract_value_for_ast_node(ast_node, false)
      AbstractValue.single_type_nonconst(method_type).propagate(def_av)
      def_av
    end

    def process_const_path_ref(ast_node)
      ast_node.map do |n|
        process_ast_node(n)
      end.last
    end

    def process_top_const_ref(ast_node)
      YARD::Registry.abstract_value(ast_node)
    end

    def process_ident(ast_node)
      av = YARD::Registry.abstract_value(ast_node)
      obj = YARD::Registry.get_object_for_ast_node(ast_node)
      if obj.is_a?(YARD::CodeObjects::MethodObject) && obj.ast_node
        method_av = process_ast_node(obj.ast_node)
        method_av.propagate(av)
      end
      av
    end

    def process_yield0(ast_node)
      YARD::Registry.abstract_value(ast_node)
    end

    def process_yield(ast_node)
      process_ast_node(ast_node[0]) # args
      YARD::Registry.abstract_value(ast_node)
    end

    def process_if(if_node)
      av = YARD::Registry.abstract_value(if_node)
      process_ast_node(if_node.condition)

      then_av = process_ast_node(if_node.then_block)
      if then_av
        then_av.propagate(av)
      end

      if if_node.else_block
        else_av = process_ast_node(if_node.else_block)
        else_av.propagate(av) if else_av
      end

      av
    end

    alias process_unless process_if
    alias process_elsif process_if
    alias process_if_mod process_if
    alias process_unless_mod process_if

    # ternary
    def process_ifop(node)
      process_ast_node(node[0]) # condition
      av = YARD::Registry.abstract_value(node)
      then_av = process_ast_node(node[1])
      then_av.propagate(av)
      else_av = process_ast_node(node[2])
      else_av.propagate(av)
      av
    end

    def process_do_block(ast_node)
      process_ast_node(ast_node[1])
    end
    alias process_brace_block process_do_block

    def process_begin(node)
      # TODO(sqs): this is not comprehensive
      process_ast_node(node[0][0])
    end

    def process_nil_control_flow_kw(node)
      AbstractValue.nil_type
    end

    alias process_retry process_nil_control_flow_kw
    alias process_break process_nil_control_flow_kw
    alias process_next process_nil_control_flow_kw

    # TODO(sqs): kind of a stretch to call this a control flow kw
    alias process_undef process_nil_control_flow_kw

    def process_rescue(node)
      # TODO(sqs): this is not comprehensive
      process_ast_node(node[2])
    end

    def process_ensure(node)
      # TODO(sqs): this is not comprehensive
      process_ast_node(node[0])
    end

    def process_finally(node)
      # TODO(sqs): this is not comprehensive
      process_ast_node(node[0])
    end

    def process_rescue_mod(node)
      expr1 = process_ast_node(node[0])
      expr2 = process_ast_node(node[1])
      av = YARD::Registry.abstract_value(node)
      expr1.propagate(av)
      expr2.propagate(av)
      av
    end

    def process_loop(node)
      process_ast_node(node.condition)
      process_ast_node(node.block)
    end

    def process_for(node)
      process_ast_node(node[0])
      process_ast_node(node[1])
      process_ast_node(node.block)
    end

    alias process_while process_loop
    alias process_until process_loop
    alias process_while_mod process_loop
    alias process_until_mod process_loop

    def process_case(node)
      process_ast_node(node[0]) if node[0] # switch var
      process_ast_node(node[1])
    end

    def process_when(node)
      process_ast_node(node[0]) # condition
      av = YARD::Registry.abstract_value(node)
      then_av = process_ast_node(node[1])
      then_av.propagate(av)

      others = node[2]
      if others
        if others.type == :when
          other_cases_av = process_ast_node(others)
          other_cases_av.propagate(av)
        elsif others.type == :else
          else_av = process_ast_list(others[0])
          else_av.propagate(av)
        end
      end

      av
    end

    def process_binary(node)
      left, right = node[0], node[2]
      op = node[1]

      left_av = process_ast_node(left)
      right_av = process_ast_node(right)

      # TODO(sqs): rough heuristic that is wrong in many cases
      case op.to_s
      when "&&", "||", "and", "or"
        AbstractValue.single_type(InstanceType.new("::TrueClass"))
      else
        left_av
      end
    end

    def process_unary(node)
      # TODO(sqs)
      process_ast_node(node[1])
    end

    def process_regexp_literal(node)
      # TODO(sqs): handle string_embexpr in regexps
      AbstractValue.single_type(InstanceType.new("::Regexp"))
    end

    def process_int(ast_node)
      AbstractValue.single_type(InstanceType.new("::Fixnum"))
    end

    def process_CHAR(ast_node)
      AbstractValue.single_type(InstanceType.new("::String"))
    end

    def process_float(ast_node)
      AbstractValue.single_type(InstanceType.new("::Float"))
    end

    def process_hash(ast_node)
      # if all values are same type, designate hash as having values of that type.
      types = ast_node.map { |n| process_ast_node(n) }.compact.map(&:type_string).uniq
      AbstractValue.single_type(HashInstanceType.new(types.length == 1 ? types[0] : nil))
    end

    def process_assoc(ast_node)
      process_ast_node(ast_node[1])
    end

    def process_dot2(ast_node)
      AbstractValue.single_type(InstanceType.new("::Range"))
    end
    alias process_dot3 process_dot2

    def process_array(ast_node)
      # if all array elems are same type, designate array as having elements of that type.
      types = (ast_node[0] || []).map { |n| process_ast_node(n) }.compact.map(&:type_string).uniq
      AbstractValue.single_type(ArrayInstanceType.new(types.length == 1 ? types[0] : nil))
    end

    def process_string_literal(ast_node)
      AbstractValue.single_type(InstanceType.new("::String"))
    end

    alias process_tstring_content process_string_literal
    alias process_string_concat process_string_literal

    def process_xstring_literal(ast_node)
      AbstractValue.single_type(InstanceType.new("::String"))
    end

    def process_backref(ast_node)
      # these are in regexps so they are always strings, right?
      AbstractValue.single_type(InstanceType.new("::String"))
    end

    def process_symbol_literal(ast_node)
      AbstractValue.single_type(InstanceType.new("::Symbol"))
    end

    def process_defined(ast_node)
      AbstractValue.single_type(InstanceType.new("::TrueClass"))
    end

    def process_paren(ast_node)
      process_ast_node(ast_node[0])
    end

    def process_return(return_node)
      process_ast_node(return_node[0][0])
    end

    def process_return0(return_node)
      AbstractValue.nil_type
    end

    def process_ivar(ast_node)
     YARD::Registry.abstract_value(ast_node)
    end

    def process_cvar(ast_node)
     YARD::Registry.abstract_value(ast_node)
    end

    def process_kw(ast_node)
     YARD::Registry.abstract_value(ast_node)
    end

    def process_opassign(ast_node)
      av = YARD::Registry.abstract_value(ast_node)
      rhs_av = process_ast_node(ast_node[2])
      rhs_av.propagate(av)
      av
    end

    def process_gvar(ast_node)
      YARD::Registry.abstract_value(ast_node)
    end

    def process_dyna_symbol(node)
      AbstractValue.single_type(InstanceType.new("::Symbol"))
    end

    def process_zsuper(node)
      YARD::Registry.abstract_value(node)
    end

    def process_super(node)
      YARD::Registry.abstract_value(node)
    end

    def process_alias(node)
      AbstractValue.nil_type
    end

    def process_var_alias(node)
      AbstractValue.nil_type
    end

    def process_END(node)
      process_ast_list(node[0])
    end

    def process_var_field(ast_node)
      process_ast_node(ast_node[0])
    end

    def process_var_ref(ast_node)
      v = ast_node[0]
      ref_av = case v.type
               when :kw
                 if v[0] == "true"
                   AbstractValue.single_type(InstanceType.new("::TrueClass"))
                 elsif v[0] == "false"
                   AbstractValue.single_type(InstanceType.new("::FalseClass"))
                 elsif v[0] == "self"
                   process_ast_node(v) or raise "no obj for #{ast_node[0].source}"
                 elsif v[0] == "nil"
                   AbstractValue.nil_type
                 else
                   log.warn "unknown keyword: #{v.source} at #{ast_node.file} lines #{ast_node.line_range} (assuming string type)"
                   AbstractValue.single_type_nonconst(InstanceType.new("::String"))
                 end
               else
                 process_ast_node(v) or raise "no obj for #{ast_node[0].source}"
               end
      av = YARD::Registry.abstract_value_for_ast_node(ast_node, false)
      ref_av.propagate(av)
      av
    end

    def process_const(ast_node)
      av = YARD::Registry.abstract_value(ast_node)
      # av.constant = true # TODO(sqs): only warn, since you can reassign consts in ruby
      obj = YARD::Registry.get_object_for_ast_node(ast_node)
      if obj && obj.is_a?(YARD::CodeObjects::ClassObject)
        av.add_type(Type.from_object(obj))
      end
      av
    end

    def process_fcall(ast_node)
      av = YARD::Registry.abstract_value_for_ast_node(ast_node, false)

      method_av = process_ast_node(ast_node[0])
      method_av.types.each do |t|
        t.return_type.propagate(av) if t.is_a?(MethodType) && t.return_type
      end

      # process block
      if ast_node.block
        process_ast_node(ast_node.block)
      end

      av
    end

    def process_call(ast_node)
      av = YARD::Registry.abstract_value_for_ast_node(ast_node, false)
      recv_av = process_ast_node(ast_node[0])

      method_av = process_ast_node(ast_node[2])
      method_obj = YARD::Registry.get_object_for_ast_node(ast_node[2])

      # TODO(sqs): need to do multiple passes
      if not method_obj
        method_name = ast_node[2].last
        resolv_namespace = YARD::Registry.get_object_for_ast_node(ast_node[0]) || @namespace
        method_obj = YARD::Registry.resolve(resolv_namespace, method_name, true, true)
      end

      if method_obj && method_obj.name.to_s == "new" && !method_obj.namespace.root?
        mtype = MethodType.new(method_obj.namespace, :class, :new, method_obj)
        mtype.return_type.add_type(InstanceType.new(method_obj.namespace))
        method_av.add_type(mtype)

        # if klass.new doesn't exist but klass#initialize does, then update ref
        # that we emitted in reference_handlers.rb to point to klass#initialize.
        if method_obj.is_a?(YARD::CodeObjects::Proxy)
          initialize_method = YARD::Registry.resolve(method_obj.namespace, "#initialize", true)
          if initialize_method.is_a?(YARD::CodeObjects::MethodObject)
            YARD::Registry.delete_reference(YARD::CodeObjects::Reference.new(method_obj, ast_node[2], false))
            YARD::CodeObjects::Reference.new(initialize_method, ast_node[2])
          end
        end
      elsif recv_av
        # couldn't determine method, use inferred types
        method_name = ast_node[2].source
        method_obj = recv_av.lookup_method(method_name)
        if method_obj
          mtype = Type.from_object(method_obj)
          method_av = process_ast_node(method_obj.ast_node)

          # attr_writer we've found a new reference thanks to type inference, so add it to Registry.references
          # TODO(sqs): add a spec that tests that we add it to Registry.references
          YARD::Registry.add_reference(YARD::CodeObjects::Reference.new(method_obj, ast_node[2]))
        else
          #log.warn "Couldn't find method_obj for method #{method_name.inspect} in recv #{ast_node[0].inspect[0..40]} (recv AV is #{recv_av.inspect})"
        end
      end

      if method_av
        method_av.types.each do |t|
          t.return_type.propagate(av) if t.is_a?(MethodType) && t.return_type
          t.check! if t.is_a?(MethodType)
        end
      end

      # process block
      if ast_node.block
        process_ast_node(ast_node.block)
      end

      av
    end

    def process_vcall(ast_node)
      av = YARD::Registry.abstract_value_for_ast_node(ast_node, false)

      method_av = process_ast_node(ast_node[0])
      method_av.types.each do |t|
        t.return_type.propagate(av) if t.is_a?(MethodType) && t.return_type
      end

      # process block
      if ast_node.block
        process_ast_node(ast_node.block)
      end

      av
    end

    def process_command_call(ast_node)
      process_call(ast_node)
    end

    def process_command(ast_node)
      process_ast_list(ast_node.children)
      AbstractValue.nil_type
    end

    def process_void_stmt(_); AbstractValue.nil_type end

    def process_comment(_); nil end

    def process_registry
      # TODO
    end

    def process_C_toplevel(ast_node)
      process_ident(ast_node)
    end
  end
end

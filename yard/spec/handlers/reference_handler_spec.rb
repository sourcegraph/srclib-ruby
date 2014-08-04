require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::ReferenceHandler" do
  before(:all) { YARD::Handlers::Processor.process_references = true }
  after(:all) { YARD::Handlers::Processor.process_references = false }

  describe "simple" do
    before(:all) { parse_file :reference_handler_001, __FILE__ }

    it "should get 2 references to A" do
      Registry.references_to("A").length.should == 3
    end

    it "should get namespace qualifier reference of A" do
      refs = Registry.references_to("A")
      refs[1].ast_node.source.should == "A"
      refs[1].ast_node.source_range.should == (35..35)
    end

    it "should get top-level reference to A" do
      refs = Registry.references_to("A")
      refs[2].ast_node.source.should == "A"
      refs[2].ast_node.source_range.should == (40..40)
    end

    it "should get 2 references to B" do
      Registry.references_to("A::B").length.should == 3
    end

    it "should get reference to B in module A block" do
      refs = Registry.references_to("A::B")
      refs[1].ast_node.source.should == "B"
      refs[1].ast_node.source_range.should == (28..28)
    end

    it "should get top-level qualified reference to B" do
      refs = Registry.references_to("A::B")
      refs[2].ast_node.source.should == "B"
      refs[2].ast_node.source_range.should == (38..38)
    end
  end

  describe "nested modules" do
    before(:all) { parse_file :reference_handler_002, __FILE__ }

    it "should get 10 references to M1" do
      Registry.references_to("M1").length.should == 11
    end

    it "should get 6 references to M1::M2" do
      Registry.references_to("M1::M2").length.should == 6
    end

    it "should get 4 references to M1::M2::C1" do
      Registry.references_to("M1::M2::C1").length.should == 5
    end

    it "should get 2 references to M1::M2::C1::C2" do
      Registry.references_to("M1::M2::C1::C2").length.should == 3
    end

    it "should get 3 references to M1::M3" do
      Registry.references_to("M1::M3").length.should == 3
    end

    it "should get 1 reference to M1::M3::C3" do
      Registry.references_to("M1::M3::C3").length.should == 2
    end
  end

  describe "with `class << self` usage" do
    before(:all) { parse_file :reference_handler_003, __FILE__ }

    it "should get 6 references to C1" do
      Registry.references_to("C1").length.should == 7
    end

    it "should get 3 references to C1.my_class_method" do
      Registry.references_to("C1.my_class_method").length.should == 3
    end
  end

  describe "methods and class methods" do
    before(:all) { parse_file :reference_handler_004, __FILE__ }

    it "should get 36 references to C1" do
      Registry.references_to("C1").length.should == 37
    end

    it "should get 4 references to C1#m1" do
      Registry.references_to("C1#m1").length.should == 4
    end

    it "should get 4 references to C1#m2" do
      Registry.references_to("C1#m2").length.should == 4
    end

    it "should get 16 references to C1.cm1" do
      Registry.references_to("C1.cm1").length.should == 17
    end

    it "should get 22 references to C1.cm2" do
      Registry.references_to("C1.cm2").length.should == 22
    end

    it "should get 8 references to C1.cm3" do
      Registry.references_to("C1.cm3").length.should == 8
    end
  end

  describe "local vars" do
    before(:all) { parse_file :reference_handler_005_local_vars, __FILE__ }

    {
      "file:spec/handlers/examples/reference_handler_005_local_vars.rb.txt_local_0>v" => 2,
      "file:spec/handlers/examples/reference_handler_005_local_vars.rb.txt_local_0>#m1>v" => 2,
      "M1>_local_0>v" => 2,
      "M1::C1>_local_0>v" => 2,
      "M1::C1>_local_0>#cim1>v" => 2,
      "M1::C1>_local_0>cm1>v" => 2,
      "M1::C1>_local_0><< self_local_0>v" => 2,
      "M1>_local_0>#mm1>v" => 2,
      "M1>_local_0>#mm1>#subm1>v" => 2,
    }.each do |path, num_refs|
      it "should get #{num_refs} reference to #{path}" do
        Registry.references_to(path).length.should == num_refs
      end
    end
  end

  describe "traversing AST to get refs" do
    before(:all) { parse_file :reference_handler_006_traverse, __FILE__ }

    {
      "M" => 57,
    }.each do |path, num_refs|
      it "should get #{num_refs} reference to #{path}" do
        Registry.references_to(path).length.should == num_refs
      end
    end
  end

  describe "ivars and cvars" do
    before(:all) { parse_file :reference_handler_007_ivars_cvars, __FILE__ }

    {
      'A::@iv1' => 3,
      "A::@@cv1" => 3,
    }.each do |path, num_refs|
      it "should get #{num_refs} references to #{path}" do
        Registry.at(path).should_not be_nil
        Registry.references_to(path).length.should == num_refs
      end
    end
  end

  describe "type inferenced refs" do
    before(:all) do
      parse_file :reference_handler_008_type_inference, __FILE__
      YARD::TypeInference::Processor.new.process_ast_list(YARD::Registry.ast)
    end

    {
      'Z#f' => 4,
      'Z#initialize' => 3,
    }.each do |path, num_refs|
      it "should get #{num_refs} reference to #{path}" do
        Registry.references_to(path).length.should == num_refs
      end
    end
  end

  describe "type inferenced refs to instance methods (009)" do
    before(:all) do
      parse_file :reference_handler_009_type_inference_imethods, __FILE__
      YARD::TypeInference::Processor.new.process_ast_list(YARD::Registry.ast)
    end

    {
      'A#im' => 3,
    }.each do |path, num_refs|
      it "should get #{num_refs} reference to #{path}" do
        Registry.references_to(path).length.should == num_refs
      end
    end
  end

  describe "multiple files (010)" do
    before(:all) do
      parse_file [:reference_handler_010_multi_files_1, :reference_handler_010_multi_files_2], __FILE__
      YARD::TypeInference::Processor.new.process_ast_list(YARD::Registry.ast)
    end

    {
      'M' => 6,
      'M::C' => 5,
      'M::C#im' => 4,
      'M::C.cm' => 4,
      'M::D' => 5,
      'M::D#initialize' => 2,
      'M::D#im' => 0,
      'M::D.cm' => 0,
    }.each do |path, num_refs|
      it "should get #{num_refs} reference to #{path}" do
        Registry.references_to(path).length.should == num_refs
      end
    end
  end

  pending "type inferenced refs to module functions (011)" do
    before(:all) do
      parse_file :reference_handler_011_type_inference_module_functions, __FILE__
      YARD::TypeInference::Processor.new.process_ast_list(YARD::Registry.ast)
    end

    {
      'A.f' => 2,
    }.each do |path, num_refs|
      it "should get #{num_refs} reference to #{path}" do
        # TODO(sqs): This mimics what Ruby core base64.rb does. We should
        # resolve the two kinds of refs to module_functions (A.f from anywhere
        # and A#f from class that mixes-in A) to the same A.f or A#f (not sure
        # which one is the best to pretend is the canonical one).
        Registry.references_to(path).length.should == num_refs
      end
    end
  end

  pending "external refs (stdlib: URI)" do
    before(:all) do
      srcs = Dir[File.join(ENV['RUBY_SRC'], "lib/{uri.rb,uri/{generic,common,http}.rb}")] + ["reference_handler_011_stdlib_uri.rb.txt"]
      parse_files srcs, __FILE__
      YARD::TypeInference::Processor.new.process_ast_list(YARD::Registry.ast)
    end

    {
      "URI" => 1,
      "URI.parse" => 1,
      "URI::Generic#hostname" => 1,
    }.each do |path, num_refs|
      it "should get #{num_refs} reference to #{path}" do
        Registry.references.values.each do |refs|
          refs.each do |ref|
            puts "REF #{ref.target}" unless ref.ast_node.file.start_with?(ENV["RUBY_SRC"])
          end
        end
        Registry.references_to(path).select { |r| !r.ast_node.file.start_with?(ENV["RUBY_SRC"]) and not r.target.is_a?(YARD::CodeObjects::Proxy) }.length.should == num_refs
      end
    end
  end if ENV["RUBY_SRC"]

  describe "external refs (stdlib: IPAddr)" do
    before(:all) do
      srcs = Dir[File.join(ENV['RUBY_SRC'], "lib/ipaddr.rb")] + ["reference_handler_011_stdlib_ipaddr.rb.txt"]
      parse_files srcs, __FILE__
      YARD::TypeInference::Processor.new.process_ast_list(YARD::Registry.ast)
    end

    {
      'IPAddr' => 1,
      'IPAddr#initialize' => 1,
      'IPAddr#reverse' => 1,
    }.each do |path, num_refs|
      it "should get #{num_refs} reference to #{path}" do
        Registry.references_to(path).select { |r| !r.ast_node.file.start_with?(ENV["RUBY_SRC"]) and not r.target.is_a?(YARD::CodeObjects::Proxy) }.length.should == num_refs
      end
    end
  end if ENV["RUBY_SRC"]

  describe "external refs (stdlib: core)" do
    before(:all) do
      srcs = Dir[File.join(ENV['RUBY_SRC'], "{array,string}.c")] + ["reference_handler_011_stdlib_core.rb.txt"]
      parse_files srcs, __FILE__
      YARD::TypeInference::Processor.new.process_ast_list(YARD::Registry.ast)
    end

    {
      'Array' => 1,
      'Array#length' => 1,
      'String' => 1,
      'String#length' => 1,
    }.each do |path, num_refs|
      it "should get #{num_refs} reference to #{path}" do
        Registry.at(path).should_not be_nil
        Registry.references_to(path).select { |r| not r.target.is_a?(YARD::CodeObjects::Proxy) }.length.should == num_refs
      end
    end
  end if ENV["RUBY_SRC"]

  pending "refs to method params"

  pending "refs to subclassed methods" do
    before(:all) { parse_file :reference_handler_012_subclasses, __FILE__ }

    # TODO(sqs): refs to C::D#im are getting tagged as refs to C#im for some reason.
    {
      'C#im' => 2,
      "C::D#im" => 2,
    }.each do |path, num_refs|
      it "should get #{num_refs} references to #{path}" do
        Registry.at(path).should_not be_nil
        Registry.references_to(path).length.should == num_refs
      end
    end
  end

  describe "refs to C defs" do
    before(:all) do
      parse_files ['reference_handler_013_c_defs.c', 'reference_handler_013_c_defs.rb.txt'], __FILE__
      YARD::TypeInference::Processor.new.process_ast_list(YARD::Registry.ast)
    end

    {
      "String#im" => 1,
      "String.cm" => 1
    }.each do |path, num_refs|
      it "should get #{num_refs} references to #{path}" do
        Registry.at(path).should_not be_nil
        Registry.references_to(path).length.should == num_refs
      end
    end
  end


  describe "block vars" do
    before(:all) { parse_file :reference_handler_014_block_vars, __FILE__ }

    {
      # TODO(sqs): for the blockvar declarations, we don't get refs to them. this is because the ReferenceHandlers operate in a separate traversal from the BlockHandler, and so it's hard to know how to traverse into the blocks and generate the local scopes using the same logic in BlockHandler. A better solution would be to emit refs when we encounter them in the normal handler pass, which would mean emitting blockvar decls in the ParameterHandlerMethods handle_params method.
      "file:spec/handlers/examples/reference_handler_014_block_vars.rb.txt_local_0>x" => 2,
      "file:spec/handlers/examples/reference_handler_014_block_vars.rb.txt_local_0>y" => 4,
      "file:spec/handlers/examples/reference_handler_014_block_vars.rb.txt_local_0>@block_local_0>x" => 1,
      "file:spec/handlers/examples/reference_handler_014_block_vars.rb.txt_local_0>@block_local_1>x" => 1,
    }.each do |path, num_refs|
      it "should get #{num_refs} references to #{path}" do
        Registry.at(path).should_not be_nil
        Registry.references_to(path).length.should == num_refs
      end
    end
  end
end

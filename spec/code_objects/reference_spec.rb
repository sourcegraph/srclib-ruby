require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::Reference do
  describe '#inheritance_tree' do
    before(:all) do
      Registry.clear
      @target = ModuleObject.new(:root, :SomeMixin)
    end

    it "should add reference to the registry" do
      ref = Reference.new(@target, YARD::Parser::Ruby::AstNode.new(:var_ref, []))
      Registry.references[@target.path].should == [ref]
    end
  end
end

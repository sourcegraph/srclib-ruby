require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::LocalVariableHandler" do
  before(:all) {
    YARD::Handlers::Processor.process_references = true
    parse_file :local_variable_handler_001, __FILE__
  }
  after(:all) { YARD::Handlers::Processor.process_references = false }

  it "should parse local variables at the top level" do
    obj = Registry.at("file:spec/handlers/examples/local_variable_handler_001.rb.txt_local_0>somevar")
    obj.source.should == "somevar = \"top level\""
    obj.rhs.source.should == '"top level"'
  end

  it "should parse local variables inside modules" do
    obj = Registry.at("A>_local_0>somevar")
    obj.source.should == "somevar = \"in module\""
    obj.rhs.source.should == '"in module"'
  end

  it "should parse local variables inside classes" do
    obj = Registry.at("A::B>_local_0>somevar")
    obj.source.should == "somevar = \"in class\""
    obj.rhs.source.should == '"in class"'
  end

  it "should parse local variables inside singleton classes" do
    obj = Registry.at("A::B>_local_0><< self_local_0>somevar")
    obj.source.should == "somevar = \"in singleton class\""
    obj.rhs.source.should == '"in singleton class"'
  end

  it "should parse local variables inside methods" do
    obj = Registry.at("A::B>_local_0>#method>somevar")
    obj.source.should == "somevar = \"in method\""
    obj.rhs.source.should == '"in method"'
  end

  it "should parse method parameters" do
    obj = Registry.at("C>_local_0>#f>a")
    obj.source.should == "a"
    obj.rhs.should == nil
  end

  it "should parse optional method parameters" do
    obj = Registry.at("C>_local_0>#g>a")
    obj.source.should == 'a = "x"'
    obj.rhs.source.should == '"x"'
  end

  it "should parse variable length params" do
    obj = Registry.at("C>_local_0>#h>a")
    obj.source.should == 'a'
    obj.rhs.should == nil
  end

  it "should parse keyword params (in hash)" do
    obj = Registry.at("C>_local_0>#i>a")
    obj.source.should == 'a'
    obj.rhs.should == nil
  end

  it "should parse method block params" do
    obj = Registry.at("C>_local_0>#j>a")
    obj.source.should == 'a'
    obj.rhs.should == nil
  end

  it "should parse control-flow statement local vars" do
    obj = Registry.at("file:spec/handlers/examples/local_variable_handler_001.rb.txt_local_0>x")
    obj.source.should == "x = 3"
    obj.rhs.source.should == "3"
  end

  it "should parse block params (curly brace form)" do
    obj = Registry.at("file:spec/handlers/examples/local_variable_handler_001.rb.txt_local_0>@block_local_0>p")
    obj.source.should == "p"
    obj.rhs.should == nil
  end

  it "should parse block params (do-end form)" do
    obj = Registry.at("file:spec/handlers/examples/local_variable_handler_001.rb.txt_local_0>@block_local_1>q")
    obj.source.should == "q"
    obj.rhs.should == nil
  end
end

require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::TypeInference::AbstractValue" do
  before(:each) do
    @av = AbstractValue.new
    @type = InstanceType.new("Qux")
  end

  describe "adding types" do
    it "should add a type" do
      @av.types.should == []
      @av.add_type(@type)
      @av.types.should == [@type]
    end

    it "should not add a duplicate type" do
      @av.types.should == []
      @av.add_type(@type)
      @av.add_type(@type)
      @av.types.should == [@type]
    end
  end

  describe "propagation" do
    it "should propagate existing types to the target" do
      av2 = AbstractValue.new
      @av.add_type(@type)
      av2.types.should == []
      @av.propagate(av2)
      av2.types.should == [@type]
    end

    it "should propagate types added in the future to the target" do
      av2 = AbstractValue.new
      @av.propagate(av2)
      av2.types.should == []
      @av.add_type(@type)
      av2.types.should == [@type]
    end

    it "should not propagate multiple times to the same target/forward" do
      av2 = AbstractValue.new
      @av.add_type(@type)
      @av.propagate(av2)
      @av.propagate(av2)
      type2 = InstanceType.new("Foo")
      @av.add_type(type2)
      av2.types.should == [@type, type2]
    end
  end
end

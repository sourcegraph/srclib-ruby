require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::TypeInference::Processor" do
  describe "simple" do
    check_file_inline_type_annotations(:inferencer_001_simple, __FILE__)
  end

  describe "method calls" do
    check_file_inline_type_annotations(:inferencer_002_calls, __FILE__)
  end

  describe "instantiation" do
    check_file_inline_type_annotations(:inferencer_003_instantiation, __FILE__)
  end

  describe "circular" do
    check_file_inline_type_annotations(:inferencer_004_circular, __FILE__)
  end

  describe "method with args" do
    check_file_inline_type_annotations(:inferencer_005_method_args, __FILE__)
  end

  describe "instance method with args" do
    check_file_inline_type_annotations(:inferencer_006_imethod_args, __FILE__)
  end

  describe "constructor with args" do
    check_file_inline_type_annotations(:inferencer_007_ctr_args, __FILE__)
  end

  describe "cvars and ivars" do
    check_file_inline_type_annotations(:inferencer_008_cvars_ivars, __FILE__)
  end

  describe "instance methods called externally" do
    check_file_inline_type_annotations(:inferencer_009_external_imethods, __FILE__)
  end

  describe "process all AST nodes" do
    check_file_inline_type_annotations(:inferencer_010_process_ast, __FILE__)
  end

  describe "get method return types" do
    check_file_inline_type_annotations(:inferencer_011_method_return_types, __FILE__)
  end

  describe "complex propagation" do
    check_file_inline_type_annotations(:inferencer_012_complex_propagation, __FILE__)
  end

  describe "literals" do
    check_file_inline_type_annotations(:inferencer_013_literals, __FILE__)
  end

  describe "indexing" do
    check_file_inline_type_annotations(:inferencer_014_indexing, __FILE__)
  end
end

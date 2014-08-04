require "benchmark"
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'yard'))
require 'logger'
require 'ruby-prof'

PATH_ORDER = [
  'lib/yard/autoload.rb',
  'lib/yard/code_objects/base.rb',
  'lib/yard/code_objects/namespace_object.rb',
  'lib/yard/handlers/base.rb',
  'lib/yard/generators/helpers/*.rb',
  'lib/yard/generators/base.rb',
  'lib/yard/generators/method_listing_generator.rb',
  'lib/yard/serializers/base.rb',
  'lib/yard/code_objects/**/*.rb'
]

YARD::Registry.clear
YARD::Registry.init_type_inference
YARD::Handlers::Processor.process_references = true
YARD.parse PATH_ORDER, [], Logger::ERROR

RubyProf.start

Benchmark.bm do |x|
  x.report("infer types") do
    YARD::TypeInference::Processor.new.process_ast_list(YARD::Registry.ast)
  end
end

result = RubyProf.stop

printer = RubyProf::FlatPrinter.new(result)
printer.print(File.open("prof.out", "w"))

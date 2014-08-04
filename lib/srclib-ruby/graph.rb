require 'json'
require 'optparse'

module Srclib
  class Graph
    def self.summary
      "analyze Ruby code for defs and refs"
    end

    def option_parser
      OptionParser.new do |opts|
        opts.banner = "Usage: graph [options] < unit.json"
      end
    end

    def run(args)
      option_parser.order!
      # raise "no args may be specified to graph (got #{args.inspect}); it only graphs the current directory and accepts a JSON repr of a source unit via stdin" if args.length != 0

      # TODO
      puts "{}"
    end

    def initialize
      @opt = {}
    end

    private

  end
end

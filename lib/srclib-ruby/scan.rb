require 'json'
require 'optparse'

module Srclib
  class Scan
    def self.summary
      "discover Ruby gems/apps in a dir tree"
    end

    def option_parser
      OptionParser.new do |opts|
        opts.banner = "Usage: scan [options]"
        opts.on("--repo URI", "URI of repository") do |v|
          @opt[:repo] = v
        end
        opts.on("--subdir DIR", "path of current dir relative to repo root") do |v|
          @opt[:repo_subdir] = v
        end
      end
    end

    def run(args)
      option_parser.order!
      raise "no args may be specified to scan (got #{args.inspect}); it only scans the current directory" if args.length != 0

      source_units = find_gems('.').map do |gemspec, gem|
        {
          'Name' => gem[:name],
          'Type' => 'rubygem',
          'Files' => gem[:files],
          'Dependencies' => gem[:dependencies],
          'Data' => gem,
          'Ops' => {'depresolve' => nil, 'graph' => nil},
        }
      end
      puts JSON.generate(source_units)
    end

    def initialize
      @opt = {}
    end

    private

    def find_gems(dir)
      dir = File.expand_path(dir)
      gemspecs = {}
      spec_files = Dir.glob(File.join(dir, "**/*.gemspec"))
      spec_files.each do |spec_file|
        Dir.chdir(File.expand_path(File.dirname(spec_file), dir))
        spec = Gem::Specification.load(spec_file)
        if spec
          spec.normalize
          o = {}
          spec.class.attribute_names.find_all do |name|
            v = spec.instance_variable_get("@#{name}")
            o[name] = v if v
          end
          gemspecs[spec_file] = o
        end
      end
      gemspecs
    end
  end
end

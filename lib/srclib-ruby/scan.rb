require 'json'
require 'optparse'
require 'bundler'
require 'pathname'

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

      pre_wd = Pathname.pwd

      source_units = find_gems('.').map do |gemspec, gem|
        Dir.chdir(File.dirname(gemspec))
        if File.exist?("Gemfile")
          deps = Bundler.definition.dependencies.map{ |d| [d.name, d.requirement.to_s] }
        end

        gem_dir = Pathname.new(gemspec).relative_path_from(pre_wd).parent

        gem.delete(:date)
        {
          'Name' => gem[:name],
          'Type' => 'rubygem',
          'Dir' => gem_dir,
          'Files' => gem[:files].sort.map { |f| gem_dir == "." ? f : File.join(gem_dir, f) },
          'Dependencies' => (deps and deps.sort), #gem[:dependencies], # TODO(sqs): what to do with the gemspec deps?
          'Data' => gem,
          'Ops' => {'depresolve' => nil, 'graph' => nil},
        }
      end

      Dir.chdir(pre_wd) # Reset working directory to initial root
      source_units += find_scripts('.', source_units).map do |script_path|
        Dir.chdir(File.dirname(script_path))

        script_dir = Pathname.new(script_path).relative_path_from(pre_wd).parent
        script_file = File.basename(script_path)
        script_name = (script_dir.to_path == '.' ? script_file : File.join(script_dir, script_file))

        {
          'Name' => script_name,
          'Type' => 'rubyscript',
          'Dir' => script_dir,
          'Files' => [script_name],
          'Dependencies' => nil, #TODO: Find all requires, and match it with currently installed gems
          'Data' => {
            'name' => script_name,
            'files' => [script_file]
          },
          'Ops' => {'depresolve' => nil, 'graph' => nil},
        }
      end

      puts JSON.generate(source_units.sort_by { |a| a['Name'] })
    end

    def initialize
      @opt = {}
    end

    private

    # Checks to see if the given script file is accounted for
    # in the files of the given source units.
    # @return [Boolean] Returns false if the script is not accounted for
    def script_in_units(script_file, units)
      script_absolute = File.expand_path(script_file)

      units.each do |unit|
        unit_dir = File.expand_path(unit['Dir'])
        unit['Data'][:files].each do |file|
          if File.join(unit_dir, file) == script_file
            return true
          end
        end
      end

      return false
    end

    # Finds all scripts that are not accounted for in the existing set of found gems
    # @param dir [String] The directory in which to search for scripts
    # @param gem_units [Array] The source units that have already been found.
    def find_scripts(dir, gem_units)
      scripts = []

      dir = File.expand_path(dir)
      Dir.glob(File.join(dir, "**/*.rb")).map do |script_file|
        if !script_in_units(script_file, gem_units)
          scripts << script_file
        end
      end

      scripts
    end

    def find_gems(dir)
      dir = File.expand_path(dir)
      gemspecs = {}
      spec_files = Dir.glob(File.join(dir, "**/*.gemspec")).sort
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
          if o[:files]
            o[:files].sort!
          end
          if o[:metadata] && o[:metadata].empty?
            o.delete(:metadata)
          end
          o.delete(:rubygems_version)
          o.delete(:specification_version)
          gemspecs[spec_file] = o
        end
      end
      gemspecs
    end
  end
end

require 'json'
require 'optparse'
require 'bundler'
require 'pathname'
require 'set'

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

      # Keep track of already discovered files in a set
      discovered_files = Set.new

      source_units = find_gems('.').map do |gemspec, gem|
        Dir.chdir(File.dirname(gemspec))
        if File.exist?("Gemfile")
          deps = Bundler.definition.dependencies.map{ |d| [d.name, d.requirement.to_s] }
        end

        gem_dir = Pathname.new(gemspec).relative_path_from(pre_wd).parent

        gem.delete(:date)

        # Add set of all now accounted for files, using absolute paths
        discovered_files.merge(gem[:files].sort.map { |x| File.expand_path(x) } )

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

      # Ignore standard library
      if @opt[:repo] != "github.com/ruby/ruby"
        Dir.chdir(pre_wd) # Reset working directory to initial root
        scripts = find_scripts('.', source_units).map do |script_path|
          Pathname.new(script_path).relative_path_from(pre_wd)
        end

        # Filter out scripts that are already accounted for in the existing Source Units
        scripts = scripts.select do |script_file|
          script_absolute = File.expand_path(script_file)
          member = discovered_files.member? script_absolute
          !member
        end
        scripts.sort! # For testing consistency

        # If scripts were found, append to the list of source units
        if scripts.length > 0
          if File.exist?("Gemfile")
            deps = Bundler.definition.dependencies.map{ |d| [d.name, d.requirement.to_s] }
          end

          source_units << {
            'Name' => '.',
            'Type' => 'ruby',
            'Dir' => '.',
            'Files' => scripts,
            'Dependencies' => (deps and deps.sort),
            'Data' => {
              'name' => 'rubyscripts',
              'files' => scripts,
            },
            'Ops' => {'depresolve' => nil, 'graph' => nil},
          }
        end
      end

      puts JSON.generate(source_units.sort_by { |a| a['Name'] })
    end

    def initialize
      @opt = {}
    end

    private

    # Finds all scripts that are not accounted for in the existing set of found gems
    # @param dir [String] The directory in which to search for scripts
    # @param gem_units [Array] The source units that have already been found.
    def find_scripts(dir, gem_units)
      scripts = []

      dir = File.expand_path(dir)
      Dir.glob(File.join(dir, "**/*.rb")).map do |script_file|
        scripts << script_file
      end

      scripts
    end

    # Given the content of a script, finds all of its dependant gems
    # @param script_code [String] Content of the script
    # @return [Array] The dependency array.
    def script_deps(script_code)
      # Get a list of all installed gems
      installed_gems = `gem list`.split(/\n/).map do |line|
        line.split.first.strip #TODO: Extract version number
      end

      deps = []
      script_code.scan(/require\W["'](.*)["']/) do |required|
        if installed_gems.include? required[0].strip
          deps << [
            required[0].strip,
            ">= 0" #TODO: Should use the currently installed version number
          ]
        end
      end

      return deps
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

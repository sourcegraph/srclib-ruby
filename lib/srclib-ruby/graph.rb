require 'json'
require 'optparse'
require 'bundler'
require 'rubygems'
require 'rubygems/user_interaction'

Encoding.default_internal = Encoding::UTF_8
Encoding.default_external = Encoding::UTF_8

if ENV['IN_DOCKER_CONTAINER'] == 'true'
  # super hacky, but prevent trying to write to Gemfile.lock (since it's a
  # readonly volume and there's no point to writing to it anyway)
  class Bundler::Definition
    def ensure_equivalent_gemfile_and_lockfile(x);end
  end
end

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
      if Gem.win_platform?
        opt_args = []
        args.map do |arg|
          opt_args << arg.sub(/^\//, '--')
        end
        args = opt_args
      end
      option_parser.order!(args)

      # TODO(sqs): this chdir is for debugging only, remove it when not needed
      if ENV['TESTING_CWD']
        Dir.chdir(ENV['TESTING_CWD'])
      end

      # send rubygems log output to stderr, not stdout (default)

      if Gem.win_platform?
        dev_null = 'NUL'
      else
        dev_null = '/dev/null'
      end
      Gem::DefaultUserInteraction.ui = Gem::StreamUI.new(File.open(dev_null, 'r'), STDERR, STDERR, false)

      # raise "no args may be specified to graph (got #{args.inspect}); it only graphs the current directory and accepts a JSON repr of a source unit via stdin" if args.length != 0

      srcunit = JSON.parse(STDIN.read)

      if ENV['IN_DOCKER_CONTAINER'] == 'true' and File.exist?("Gemfile")
        # avoid trying to write config to .bundle/config on readonly volume
        ENV['BUNDLE_APP_CONFIG'] = "/tmp/bundle-config"

        bundle = Bundler.definition

        # remove certain binary deps and remove current gem (hacky)
        okdeps = bundle.dependencies.reject { |d| OMIT_DEPS.include?(d.name) or d.name == srcunit['Name'] }
        Bundler.settings[:path] = "/tmp/bundle" # install to system
        Bundler.settings[:frozen] = true # avoid writing to lockfile since docker volume is readonly

        bundle = Bundler::Definition.new("Gemfile.lock", okdeps, bundle.send(:sources), bundle.instance_variable_get("@unlock"), bundle.ruby_version)

        Bundler.ui.level = 'fatal'
        Bundler::Installer.install(Bundler.root, bundle)
      end

      yard_bin = File.expand_path(File.join(__FILE__, '../../../yard/bin/yard'))
      STDERR.puts "Using yard bin at '#{yard_bin}'"

      STDERR.puts "Running yard bundle..."
      STDERR.puts `#{yard_bin} bundle --debug`

      STDERR.puts "Getting yard bundle output dirs..."
      bundle_output = `test -e Gemfile && #{yard_bin} bundle --list`
      bundle_output_dirs = bundle_output.split("\n").map { |l| l.split(/\s+/)[1] }.compact
      STDERR.puts " ==> #{bundle_output_dirs.inspect}"

      if (!srcunit['Config'] || !srcunit['Config']['noCachedStdlibYardoc'])
        bundle_output_dirs << RUBY_STDLIB_YARDOC_DIR if File.exist?(RUBY_STDLIB_YARDOC_DIR)
      end

      load_opts = ''
      if bundle_output_dirs.length > 0
        load_opts = "--load-yardoc-files #{bundle_output_dirs.join(',')}"
      end

      condense_cmd = "#{yard_bin} condense #{load_opts} #{srcunit['Files'].join(' ')}"
      STDERR.puts "Running #{condense_cmd}"
      condensed = JSON.parse(`#{condense_cmd}`)

      STDERR.puts "Finished condensing; converting to srclib graph output format"

      puts JSON.generate(convert_to_srclib_graph_format(condensed))
    end

    def initialize
      @opt = {}
    end

    private

    def seen_defn(defn)
      if seen = @seen_defs[defn['Path']]
        STDERR.puts "already seen defn with path #{defn['Path']}; skipping (prev defn is: #{seen.inspect})"
        return true
      end
      @seen_defs[defn['Path']] = defn
      false
    end

    def seen_ref(ref)
      key = "DefPath=#{ref['DefPath']} File=#{ref['File']} Start=#{ref['Start']} End=#{ref['End']}"
      if seen = @seen_refs[key]
        STDERR.puts "already seen ref with seen-key #{key}; skipping (prev ref is: #{seen.inspect})"
        return true
      end
      @seen_refs[key] = ref
      false
    end

    def convert_to_srclib_graph_format(condensed)
      @seen_defs = {}
      @seen_refs = {}
      @graph = {'Defs' => [], 'Refs' => [], 'Docs' => []}

      for obj in condensed['objects']
        defn = to_srclib_defn(obj)

        if seen_defn(defn)
          next
        end

        @graph['Defs'] << defn

        if obj['docstring'] and !obj['docstring'].empty?
          @graph['Docs'] << {
            'Path' => defn['Path'],
            'Format' => 'text/html',
            'Data' => obj['docstring'],
            'File' => obj['file'],
          }
        end


        # Defs parsed from C code have a name_range (instead of a ref with
        # decl_ident). Emit those as refs here.

        if obj['name_start'] != 0 and obj['name_end'] != 0
          name_ref = {
            'DefPath' => defn['Path'],
            'Def' => true,
            'File' => defn['File'],
            'Start' => obj['name_start'],
            'End' => obj['name_end'],
          }
          if not seen_ref(name_ref)
            @graph['Refs'] << name_ref
          end
        end
      end

      printed_gem_resolution_err = {}

      for yard_ref in condensed['references']
        ref, dep_gem_name = to_srclib_ref(yard_ref)

        if ref['DefPath'].empty?
          STDERR.puts "Warning: got ref with empty def path; skipping (ref is: #{ref.inspect})"
          next
        end

        # Determine the referenced def's repo.
        if dep_gem_name == STDLIB_GEM_NAME_SENTINEL
          # Ref to stdlib.
          ref['DefRepo'] = STDLIB_CLONE_URL
          ref['DefUnit'] = '.'
          ref['DefUnitType'] = 'ruby'
        elsif dep_gem_name and dep_gem_name != ""
          # Ref to another gem.
          begin
            gem_clone_url = Srclib::DepResolve.get_gem_clone_url(dep_gem_name)
            ref['DefRepo'] = gem_clone_url
            ref['DefUnit'] = dep_gem_name
          rescue Exception => ex
            if not printed_gem_resolution_err[dep_gem_name]
              STDERR.puts "Warning: Failed to resolve gem dependency #{dep_gem_name} to clone URL: #{ex.inspect} (continuing, not emitting reference, and suppressing future identical log messages)"
              printed_gem_resolution_err[dep_gem_name] = true
            end
            next
          end
        else
          # Internal ref to this gem. Nothing to update.
        end

        if not seen_ref(ref)
          @graph['Refs'] << ref
        end
      end

      @graph
    end

    def to_srclib_ref(yard_ref)
      ref = {
        'DefPath' => yard_object_path_to_srclib_path(yard_ref['target']),
        'Def' => yard_ref['kind'] == 'decl_ident',
        'File' => yard_ref['file'],
        'Start' => yard_ref['start'],
        'End' => yard_ref['end'],
      }
      return ref, get_gem_name_from_gem_yardoc_file(yard_ref['target_origin_yardoc_file'])
    end

    # getGemNameFromGemYardocFile converts a path to the .yardoc file or dir for a gem to the gem's name.
    def get_gem_name_from_gem_yardoc_file(gem_yardoc_file)
      if gem_yardoc_file == nil or gem_yardoc_file == ""
        return nil
      end
      if gem_yardoc_file == RUBY_STDLIB_YARDOC_DIR
        # TODO(sqs): now that we don't run YARD on the stdlib for each gem,
        # how do we determine when a ref points to the stdlib?
        return STDLIB_GEM_NAME_SENTINEL
      end

      name_ver = if gem_yardoc_file.end_with?("/.yardoc")
                   # handle paths of the form
                   # "/tmp/grapher-output-test308543943/github.com-ruth-my_ruby_gem/ruby/gems-./ruby/2.0.0/gems/sample_ruby_gem-0.0.1/.yardoc"
                   File.basename(File.dirname(gem_yardoc_file))
                 elsif gem_yardoc_file.end_with?(".yardoc")
                   File.basename(gem_yardoc_file.sub(/\.yardoc$/, ''))
                 else
                   raise "Unrecognized gem yardoc file #{gem_yardoc_file.inspect}"
                 end

      i = name_ver.rindex('-')
      if i == nil
        name_ver
      else
        name_ver[0..i-1]
      end
    end

    # obj is a YARD object
    def to_srclib_defn(obj)
      {
        'Path' => yard_object_path_to_srclib_path(obj['path']),
        'TreePath' => yard_object_path_to_srclib_treepath(obj['path']),
        'Name' => obj['name'],
        'Kind' => RUBY_OBJECT_TYPE_MAP[obj['type']],
        'Exported' => obj['exported'],
        'File' => obj['file'],
        'DefStart' => obj['def_start'],
        'DefEnd' => obj['def_end'],
        'Test' => !!(/(_test\.rb|_spec\.rb)$/.match(obj['file']) or /(specs?|tests?)\//.match(obj['file'])),
        'Data' => {
          # NOTE: This should be kept in sync with the def formatter in this
          # repository (which is written in Go).
          'RubyKind' => obj['type'],
          'TypeString' => obj['type_string'],
          'Signature' => obj['signature'],
          'Module' => obj['module'],
          'RubyPath' => obj['path'],
          'ReturnType' => obj['return_type'],
        },
      }
    end

    def yard_object_path_to_srclib_path(p)
      p = p.dup
      p.gsub!(".rb", "_rb")
      p.gsub!("::", "/")
      p.gsub!("#", "/$methods/")
      p.gsub!(".", "/$classmethods/")
      p.gsub!(">", "@")
      p.gsub!(/^\//, "")
      p
    end

    def yard_object_path_to_srclib_treepath(p)
      p = p.dup
      p.gsub!(".rb", "_rb")
      p.gsub!("::", "/")
      p.gsub!("#", "/")
      p.gsub!(".", "/")
      p.gsub!(">", "/")
      p.gsub!(/^\//, "")

      # Strip out path components that exist solely to make this path
      # unique and are not semantically meaningful.
      meaningful_parts = p.split("/").reject { |c| c.empty? or c.start_with?("$") or c.start_with?("_local_") }
      "./#{meaningful_parts.join('/')}"
    end
  end
end

OMIT_DEPS = ["pg", "nokigiri", "rake", "mysql", "bcrypt-ruby", "debugger", "debugger-linecache", "debugger-ruby_core_source", "tzinfo"]

RUBY_OBJECT_TYPE_MAP = {
  "method" =>           "func",
  "constant" =>         "const",
  "class" =>            "type",
  "module" =>           "module",
  "localvariable" =>    "var",
  "instancevariable" => "var",
  "classvariable" =>    "var",
}

STDLIB_GEM_NAME_SENTINEL = "<RUBY_STDLIB>"

STDLIB_CLONE_URL = "https://github.com/ruby/ruby.git"

RUBY_STDLIB_YARDOC_DIR = File.expand_path("../../../ruby-#{RUBY_VERSION}/.yardoc", __FILE__)

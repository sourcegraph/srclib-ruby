require_relative '../parser/ruby/ast_node'

module YARD
  module CLI
    # Condense all objects
    # @since 0.8.6
    class Condense < Yardoc
      def description; 'Condenses all objects' end

      def initialize(*args)
        super
        @files = []
        @load_yardoc_files = []

        Logger.instance.io = STDERR
        log.show_backtraces = true
      end

      # Runs the commandline utility, parsing arguments and displaying an object
      # from the {Registry}.
      #
      # @param [Array<String>] args the list of arguments.
      # @return [void]
      def run(*args)
        return unless parse_arguments(*args)
        @serializer = Serializers::JSONSerializer.new(self.files)
        @serializer.before_serialize
        @serializer.serialize({objects: Registry.all, references: Registry.references})
        @serializer.after_serialize

        print_stats
      end

      def print_stats
        STDERR.puts "============ STATS ============"
        STDERR.puts "Objects:    #{Registry.paths.length}"
      end

      # Parses commandline options.
      # @param [Array<String>] args each tokenized argument
      def parse_arguments(*args)
        opts = OptionParser.new
        opts.banner = "Usage: yard condense [options]"
        opts.on('--load-yardoc-files FILES', 'load these yardoc files and merge with current registry (provided by `-c` flag)') do |yfiles|
          @load_yardoc_files = yfiles.split(',')
        end
        general_options(opts)
        parse_options(opts, args)

        Registry.init_type_inference
        YARD::Handlers::Processor.process_references = true

        parse_files(*args) unless args.empty?
        log.warn "Loading main yardoc file at #{YARD::Registry.yardoc_file}"
        Registry.load! if use_cache
        Registry.clear if Registry.root.nil?

        Registry.each do |object|
          object.origin_yardoc_file = YARD::Registry.yardoc_file
        end

        @load_yardoc_files.each do |yfile|
          log.warn "Loading yardoc file at #{yfile}"
          rs = YARD::RegistryStore.new
          ok = rs.load!(yfile)
          if not ok
            log.warn "Failed to load yardoc file at #{yfile}"
            next
          end
          i = 0
          rs.values.each do |object|
            object.origin_yardoc_file = yfile
            YARD::Registry.register(object)

            if i % 100 == 0
              log.warn " ... Loaded #{i}/#{rs.values.length} objects from aux file #{yfile}"
            end
            i += 1
          end
          log.warn "Finished loading #{rs.values.length} objects from from aux file #{yfile}"
        end
        log.warn "Finished loading from aux yardoc files"

        YARD.parse(self.files, [])
        TypeInference::Processor.new.process_ast_list(YARD::Registry.ast)
        true
      end

      # Parses the file arguments into Ruby files.
      #
      # @example Parses a set of Ruby source files
      #   parse_files %w(file1 file2 file3)
      # @param [Array<String>] files the list of files to parse
      # @return [void]
      def parse_files(*files)
        files.each do |file|
          self.files << file
        end
      end
    end
  end
end

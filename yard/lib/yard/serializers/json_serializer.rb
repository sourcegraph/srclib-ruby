require 'json'
require 'pathname'

module YARD
  module Serializers
    class JSONSerializer < Base
      # only emit symbols and refs defined in these files
      def initialize(files)
        @files = files.map do |f|
          f = Pathname.new(f)
          if f.directory?
            fs = []
            f.find { |p|
              fs << p if p.file?
            }
            fs
          else
            [f]
          end
        end.flatten.map(&:to_s).map do |f|
          # remove leading "./"
          f.gsub(/^\.\//, '')
        end
      end

      def serialize(data)
        data = {
          :objects => data[:objects].select { |o| output_object?(o) }.map { |o| prepare_object(o) },
          :references => (data[:references] || {}).values.flatten.select { |r| output_reference?(r) }.map { |r| prepare_reference(r) },
        }
        print(JSON.fast_generate(data))
      end

      def after_serialize
        print("\n")
      end

      def output_object?(object)
        object.parent_module && object.ast_node && @files.include?(object.ast_node.file)
      end

      def prepare_object(object)
        o = {
          :name => object.name,
          :path => object.path,
          :module => object.parent_module,
          :type => object.type,
          :file => object.file,
          :exported => !object.name.to_s.include?('_local_') && !object.name.to_s.include?('@'),
        }

        if object.respond_to?(:name_range) && object.name_range
          o[:name_start] = object.name_range.first
          o[:name_end] = object.name_range.last
        end

        if object.ast_node.respond_to?(:source_range) && object.ast_node.source_range
          o[:def_start] = object.ast_node.source_range.first
          o[:def_end] = object.ast_node.source_range.last + 1
        end

        if !object.docstring.empty?
          o[:docstring] = begin
                            object.format(:format => :html, :markup => :rdoc, :template => :sourcegraph)
                          rescue
                            "<!-- doc error -->"
                          end
        end

        if av = Registry.abstract_value_for_object(object)
          o[:type_string] = av.type_string
          if av.respond_to? :return_types
            o[:return_type] = av.return_types.map(&:type_string).join(", ")
          end
        end

        case object.type
        when :method
          o[:signature] = object.signature.sub('def ', '') if object.signature
        end
        o
      end

      def output_reference?(ref)
        @files.include?(ref.ast_node.file) && !ref.target.is_a?(YARD::CodeObjects::Proxy)
      end

      def prepare_reference(ref)
        r = {
          :target => ref.target.path,
          :kind => ref.kind,
          :file => ref.ast_node.file,
          :start => ref.ast_node.source_range.first,
          :end => ref.ast_node.source_range.last + 1,
        }
        begin
          r[:target_origin_yardoc_file] = ref.target.origin_yardoc_file.to_s
        rescue
        end
        r
      end
    end
  end
end

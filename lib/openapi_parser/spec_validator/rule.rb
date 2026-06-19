module OpenAPIParser
  class SpecValidator
    class Rule
      def self.rule_name
        name
          .split('::')
          .last
          .gsub(/([A-Z])/) { "_#{Regexp.last_match(1).downcase}" }
          .sub(/^_/, '')
          .to_sym
      end

      def initialize(version)
        @version = version
      end

      attr_reader :version

      def check(_root)
        raise NotImplementedError
      end

      private

        def violation(path:, message:)
          OpenAPIParser::SpecViolation.new(
            message: message,
            path: path,
            rule_name: self.class.rule_name,
          )
        end

        def each_schema(root, &block)
          return enum_for(:each_schema, root) unless block

          visited = {}
          walk(root, visited) do |node|
            yield node if node.is_a?(OpenAPIParser::Schemas::Schema)
          end
        end

        def walk(node, visited, &block)
          return unless node.respond_to?(:_openapi_all_child_objects)
          return if visited[node.object_id]

          visited[node.object_id] = true
          block.call(node)

          node._openapi_all_child_objects.each_value do |child|
            walk(child, visited, &block)
          end
        end
    end
  end
end

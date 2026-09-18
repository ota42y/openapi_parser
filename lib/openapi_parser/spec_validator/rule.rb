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

      # @return [Gem::Version, nil] declared OpenAPI version, nil when unknown
      attr_reader :version

      def check(_root)
        raise NotImplementedError
      end

      # @param [String] boundary like '3.1'
      # @return [Boolean] false when the version is unknown
      def version_before?(boundary)
        !version.nil? && version < Gem::Version.new(boundary)
      end

      # @param [String] boundary like '3.1'
      # @return [Boolean] false when the version is unknown
      def version_at_least?(boundary)
        !version.nil? && version >= Gem::Version.new(boundary)
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

          each_node(root, OpenAPIParser::Schemas::Schema, &block)
        end

        # yields every parsed object reachable from root that is one of klasses
        def each_node(root, *klasses)
          walk(root, {}) do |node|
            yield node if klasses.any? { |klass| node.is_a?(klass) }
          end
        end

        # escapes a map key for use in a violation path, matching object_reference
        def escape_reference(key)
          key.to_s.gsub('/', '~1')
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

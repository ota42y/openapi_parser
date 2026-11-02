module OpenAPIParser
  class SpecValidator
    module Rules
      # `query` is a 3.2 Path Item addition for the HTTP QUERY method. The
      # parse layer accepts it permissively; this rule reports the version
      # mismatch.
      class QueryMethodBefore32 < Rule
        def check(root)
          return [] unless version_before?('3.2')

          violations = []
          each_node(root, OpenAPIParser::Schemas::PathItem) do |node|
            raw = node.raw_schema
            next unless raw.is_a?(Hash) && raw.key?('query')

            violations << violation(
              path: "#{node.object_reference}/query",
              message: 'the `query` operation is a 3.2 Path Item addition; earlier documents have no such field',
            )
          end
          violations
        end
      end
    end
  end
end

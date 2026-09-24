module OpenAPIParser
  class SpecValidator
    module Rules
      # 3.2 adds `summary` to the Response Object. The parse layer accepts it
      # permissively; this rule reports the version mismatch.
      class ResponseSummaryBefore32 < Rule
        def check(root)
          return [] unless version_before?('3.2')

          violations = []
          each_node(root, OpenAPIParser::Schemas::Response) do |node|
            raw = node.raw_schema
            next unless raw.is_a?(Hash) && raw.key?('summary')

            violations << violation(
              path: "#{node.object_reference}/summary",
              message: '`summary` on a Response Object is a 3.2 addition; earlier documents have no such field',
            )
          end
          violations
        end
      end
    end
  end
end

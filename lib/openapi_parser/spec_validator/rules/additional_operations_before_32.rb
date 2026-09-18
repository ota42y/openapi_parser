module OpenAPIParser
  class SpecValidator
    module Rules
      # `additionalOperations` is a 3.2 Path Item addition for non-standard
      # HTTP methods. The parse layer accepts it permissively; this rule
      # reports the version mismatch.
      class AdditionalOperationsBefore32 < Rule
        def check(root)
          return [] unless version_before?('3.2')

          violations = []
          each_node(root, OpenAPIParser::Schemas::PathItem) do |node|
            raw = node.raw_schema
            next unless raw.is_a?(Hash) && raw.key?('additionalOperations')

            violations << violation(
              path: "#{node.object_reference}/additionalOperations",
              message: '`additionalOperations` is a 3.2 Path Item addition; earlier documents have no such field',
            )
          end
          violations
        end
      end
    end
  end
end

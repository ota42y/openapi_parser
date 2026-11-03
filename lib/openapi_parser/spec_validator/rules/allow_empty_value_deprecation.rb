module OpenAPIParser
  class SpecValidator
    module Rules
      # 3.2 deprecates `allowEmptyValue` on the Parameter Object (3.1 only
      # called it NOT RECOMMENDED). The field is still allowed but
      # discouraged, so we report it as a violation on 3.2 documents.
      class AllowEmptyValueDeprecation < Rule
        def check(root)
          return [] unless version_at_least?('3.2')

          violations = []
          each_node(root, OpenAPIParser::Schemas::Parameter) do |node|
            raw = node.raw_schema
            next unless raw.is_a?(Hash) && raw.key?('allowEmptyValue')

            violations << violation(
              path: "#{node.object_reference}/allowEmptyValue",
              message: '`allowEmptyValue` on a Parameter Object is deprecated in 3.2',
            )
          end
          violations
        end
      end
    end
  end
end

module OpenAPIParser
  class SpecValidator
    module Rules
      # `$dynamicAnchor` is the companion of `$dynamicRef` from JSON Schema
      # 2020-12, declaring the dynamic resolution point. 3.0 has nothing
      # equivalent; the rule flags it on 3.0 documents.
      class DynamicAnchorIn30 < Rule
        def check(root)
          return [] unless version == :v3_0

          violations = []
          each_schema(root) do |schema|
            next unless schema.raw_schema.is_a?(Hash) && schema.raw_schema.key?('$dynamicAnchor')

            violations << violation(
              path: schema.object_reference,
              message: '`$dynamicAnchor` is a 3.1 addition (from JSON Schema 2020-12); 3.0 has no equivalent',
            )
          end
          violations
        end
      end
    end
  end
end

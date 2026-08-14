module OpenAPIParser
  class SpecValidator
    module Rules
      # `const` is a JSON Schema 2020-12 keyword adopted by OpenAPI 3.1.
      # 3.0 does not recognize it. Detection inspects raw_schema so a
      # literal `const: null` (deliberate) still flags.
      class ConstIn30 < Rule
        def check(root)
          return [] unless version == :v3_0

          violations = []
          each_schema(root) do |schema|
            next unless schema.raw_schema.is_a?(Hash) && schema.raw_schema.key?('const')

            violations << violation(
              path: schema.object_reference,
              message: '`const` is a 3.1 addition (from JSON Schema 2020-12); 3.0 has no equivalent',
            )
          end
          violations
        end
      end
    end
  end
end

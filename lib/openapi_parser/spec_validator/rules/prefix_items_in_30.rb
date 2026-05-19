module OpenAPIParser
  class SpecValidator
    module Rules
      # `prefixItems` is JSON Schema 2020-12's positional tuple keyword.
      # 3.1 adopts it; 3.0 has no equivalent and parsing it is a spec
      # mismatch the validator should report.
      class PrefixItemsIn30 < Rule
        def check(root)
          return [] unless version == :v3_0

          violations = []
          each_schema(root) do |schema|
            next unless schema.raw_schema.is_a?(Hash) && schema.raw_schema.key?('prefixItems')

            violations << violation(
              path: schema.object_reference,
              message: '`prefixItems` is a 3.1 addition (from JSON Schema 2020-12); 3.0 has no equivalent',
            )
          end
          violations
        end
      end
    end
  end
end

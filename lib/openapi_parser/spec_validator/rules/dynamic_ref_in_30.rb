module OpenAPIParser
  class SpecValidator
    module Rules
      # `$dynamicRef` is a JSON Schema 2020-12 referencing mechanism that
      # 3.1 adopted. 3.0 does not recognize it. The parse layer keeps the
      # value as raw schema data; this rule reports the version mismatch.
      class DynamicRefIn30 < Rule
        def check(root)
          return [] unless version == :v3_0

          violations = []
          each_schema(root) do |schema|
            next unless schema.raw_schema.is_a?(Hash) && schema.raw_schema.key?('$dynamicRef')

            violations << violation(
              path: schema.object_reference,
              message: '`$dynamicRef` is a 3.1 addition (from JSON Schema 2020-12); 3.0 only knows `$ref`',
            )
          end
          violations
        end
      end
    end
  end
end

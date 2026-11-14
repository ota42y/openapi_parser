module OpenAPIParser
  class SpecValidator
    module Rules
      # `patternProperties` is a JSON Schema 2020-12 keyword that 3.1 adopted.
      # 3.0 Schema Objects do not define it. The validator checks it regardless
      # of version; this rule reports the version mismatch.
      class PatternPropertiesIn30 < Rule
        def check(root)
          return [] unless version_before?('3.1')

          violations = []
          each_schema(root) do |schema|
            next unless schema.raw_schema.is_a?(Hash) && schema.raw_schema.key?('patternProperties')

            violations << violation(
              path: schema.object_reference,
              message: '`patternProperties` is a 3.1 addition (from JSON Schema 2020-12); 3.0 Schema Objects do not define it',
            )
          end
          violations
        end
      end
    end
  end
end

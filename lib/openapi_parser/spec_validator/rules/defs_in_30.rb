module OpenAPIParser
  class SpecValidator
    module Rules
      # `$defs` is a JSON Schema 2020-12 keyword that 3.1 adopted. 3.0
      # Schema Objects do not define it. The parse layer resolves `$ref`s
      # into it regardless of version; this rule reports the version mismatch.
      class DefsIn30 < Rule
        def check(root)
          return [] unless version_before?('3.1')

          violations = []
          each_schema(root) do |schema|
            next unless schema.raw_schema.is_a?(Hash) && schema.raw_schema.key?('$defs')

            violations << violation(
              path: schema.object_reference,
              message: '`$defs` is a 3.1 addition (from JSON Schema 2020-12); 3.0 Schema Objects do not define it',
            )
          end
          violations
        end
      end
    end
  end
end

module OpenAPIParser
  class SpecValidator
    module Rules
      # A boolean schema (`true` / `false` in place of a schema object) comes
      # from JSON Schema 2020-12, which 3.1 adopts. 3.0 allows a boolean only
      # for `additionalProperties`, which is not loaded as a Schema, so any
      # Schema whose raw value is a boolean is a spec mismatch in 3.0.
      class BooleanSchemaIn30 < Rule
        def check(root)
          return [] unless version_before?('3.1')

          violations = []
          each_schema(root) do |schema|
            next unless schema.raw_schema == true || schema.raw_schema == false

            violations << violation(
              path: schema.object_reference,
              message: 'a boolean schema is a 3.1 addition (from JSON Schema 2020-12); 3.0 allows a boolean only for `additionalProperties`',
            )
          end
          violations
        end
      end
    end
  end
end

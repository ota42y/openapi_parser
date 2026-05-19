module OpenAPIParser
  class SpecValidator
    module Rules
      # `contentSchema` is a JSON Schema 2020-12 annotation adopted by 3.1.
      # The parse layer accepts it permissively; this rule reports the
      # version mismatch on 3.0 documents.
      class ContentSchemaIn30 < Rule
        def check(root)
          return [] unless version == :v3_0

          violations = []
          each_schema(root) do |schema|
            next unless schema.raw_schema.is_a?(Hash) && schema.raw_schema.key?('contentSchema')

            violations << violation(
              path: schema.object_reference,
              message: '`contentSchema` is a 3.1 addition (from JSON Schema 2020-12); 3.0 has no equivalent',
            )
          end
          violations
        end
      end
    end
  end
end

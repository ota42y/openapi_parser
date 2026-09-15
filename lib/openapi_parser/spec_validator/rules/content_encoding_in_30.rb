module OpenAPIParser
  class SpecValidator
    module Rules
      # `contentEncoding` is a JSON Schema 2020-12 annotation adopted by
      # 3.1. Metadata only, no runtime side-effects.
      class ContentEncodingIn30 < Rule
        def check(root)
          return [] unless version == :v3_0

          violations = []
          each_schema(root) do |schema|
            next unless schema.raw_schema.is_a?(Hash) && schema.raw_schema.key?('contentEncoding')

            violations << violation(
              path: schema.object_reference,
              message: '`contentEncoding` is a 3.1 addition (from JSON Schema 2020-12); 3.0 has no equivalent',
            )
          end
          violations
        end
      end
    end
  end
end

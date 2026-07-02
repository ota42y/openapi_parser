module OpenAPIParser
  class SpecValidator
    module Rules
      # In 3.1 the singular `example` keyword on a Schema is deprecated in
      # favor of the JSON Schema `examples` array. The field is still
      # allowed but discouraged, so we report it as a violation.
      class ExampleSingularDeprecation < Rule
        def check(root)
          return [] unless version == :v3_1

          violations = []
          each_schema(root) do |schema|
            next unless schema.raw_schema.is_a?(Hash) && schema.raw_schema.key?('example')

            violations << violation(
              path: schema.object_reference,
              message: 'singular `example` on a Schema is deprecated in 3.1; use the `examples` array',
            )
          end
          violations
        end
      end
    end
  end
end

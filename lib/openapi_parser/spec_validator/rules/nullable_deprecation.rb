module OpenAPIParser
  class SpecValidator
    module Rules
      # `nullable` is a 3.0 keyword that 3.1 removed in favor of
      # `type: [..., "null"]`. The field's mere presence on a 3.1 document
      # is a spec violation, regardless of true/false.
      class NullableDeprecation < Rule
        def check(root)
          return [] unless version == :v3_1

          violations = []
          each_schema(root) do |schema|
            next unless schema.raw_schema.is_a?(Hash) && schema.raw_schema.key?('nullable')

            violations << violation(
              path: schema.object_reference,
              message: '`nullable` was removed in 3.1; use `type: [..., "null"]` instead',
            )
          end
          violations
        end
      end
    end
  end
end

module OpenAPIParser
  class SpecValidator
    module Rules
      # 3.1 lets `type` be an Array of primitive type names (e.g.
      # `["string", "null"]`). 3.0 only allowed a single String, so the
      # array form on a 3.0 document is a spec violation.
      class TypeArrayIn30 < Rule
        def check(root)
          return [] unless version == :v3_0

          violations = []
          each_schema(root) do |schema|
            next unless schema.type.is_a?(Array)

            violations << violation(
              path: schema.object_reference,
              message: '`type` as an Array of primitive names is a 3.1 addition; 3.0 expects a single type String',
            )
          end
          violations
        end
      end
    end
  end
end

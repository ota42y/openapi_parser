module OpenAPIParser
  class SpecValidator
    module Rules
      # `type: "null"` was added by 3.1; 3.0 only allowed the original six
      # primitive type names. The parse layer accepts the literal anyway,
      # so we report the mismatch here. Array-form types like
      # `["string", "null"]` are covered by a separate rule.
      class TypeNullIn30 < Rule
        def check(root)
          return [] unless version == :v3_0

          violations = []
          each_schema(root) do |schema|
            next unless schema.type == 'null'

            violations << violation(
              path: schema.object_reference,
              message: '`type: "null"` is a 3.1 addition; 3.0 documents have no such primitive',
            )
          end
          violations
        end
      end
    end
  end
end

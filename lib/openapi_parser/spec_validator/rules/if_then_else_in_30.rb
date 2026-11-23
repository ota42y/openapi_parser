module OpenAPIParser
  class SpecValidator
    module Rules
      # `if`, `then` and `else` are JSON Schema 2020-12 keywords that 3.1 adopted.
      # 3.0 Schema Objects do not define them. The validator checks them regardless
      # of version; this rule reports the version mismatch.
      class IfThenElseIn30 < Rule
        KEYWORDS = %w[if then else].freeze

        def check(root)
          return [] unless version_before?('3.1')

          violations = []
          each_schema(root) do |schema|
            next unless schema.raw_schema.is_a?(Hash) && KEYWORDS.any? { |keyword| schema.raw_schema.key?(keyword) }

            violations << violation(
              path: schema.object_reference,
              message: '`if`, `then` and `else` are 3.1 additions (from JSON Schema 2020-12); 3.0 Schema Objects do not define them',
            )
          end
          violations
        end
      end
    end
  end
end

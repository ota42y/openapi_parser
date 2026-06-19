module OpenAPIParser
  class SpecValidator
    module Rules
      class ExclusiveMaximum < Rule
        def check(root)
          return [] if version == :unknown

          violations = []
          each_schema(root) do |schema|
            value = schema.exclusiveMaximum
            next if value.nil?

            case version
            when :v3_0
              if value.is_a?(Numeric)
                violations << violation(
                  path: schema.object_reference,
                  message: 'numeric exclusiveMaximum is a 3.1-only form; in 3.0 use a Boolean modifier paired with `maximum`',
                )
              end
            when :v3_1
              if value == true || value == false
                violations << violation(
                  path: schema.object_reference,
                  message: 'Boolean exclusiveMaximum is a 3.0-only form; in 3.1 use a standalone numeric bound',
                )
              end
            end
          end
          violations
        end
      end
    end
  end
end

module OpenAPIParser
  class SpecValidator
    module Rules
      class ExclusiveMinimum < Rule
        def check(root)
          return [] if version.nil?

          violations = []
          each_schema(root) do |schema|
            value = schema.exclusiveMinimum
            next if value.nil?

            if version_before?('3.1')
              if value.is_a?(Numeric)
                violations << violation(
                  path: schema.object_reference,
                  message: 'numeric exclusiveMinimum is a 3.1-only form; in 3.0 use a Boolean modifier paired with `minimum`',
                )
              end
            elsif value == true || value == false
              violations << violation(
                path: schema.object_reference,
                message: 'Boolean exclusiveMinimum is a 3.0-only form; in 3.1 use a standalone numeric bound',
              )
            end
          end
          violations
        end
      end
    end
  end
end

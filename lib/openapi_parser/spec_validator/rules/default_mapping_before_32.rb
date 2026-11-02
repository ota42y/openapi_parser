module OpenAPIParser
  class SpecValidator
    module Rules
      # `defaultMapping` on the Discriminator Object is a 3.2 addition. The
      # parse layer accepts it permissively; this rule reports the version
      # mismatch.
      class DefaultMappingBefore32 < Rule
        def check(root)
          return [] unless version_before?('3.2')

          violations = []
          each_schema(root) do |schema|
            raw = schema.raw_schema
            next unless raw.is_a?(Hash)

            discriminator = raw['discriminator']
            next unless discriminator.is_a?(Hash) && discriminator.key?('defaultMapping')

            violations << violation(
              path: "#{schema.object_reference}/discriminator/defaultMapping",
              message: '`defaultMapping` on a Discriminator Object is a 3.2 addition; earlier documents have no such field',
            )
          end
          violations
        end
      end
    end
  end
end

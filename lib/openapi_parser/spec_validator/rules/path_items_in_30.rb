module OpenAPIParser
  class SpecValidator
    module Rules
      # `components.pathItems` is a 3.1 addition. The parse layer accepts it
      # in 3.0 documents permissively; this rule reports the version
      # mismatch.
      class PathItemsIn30 < Rule
        def check(root)
          return [] unless version == :v3_0

          components = root.components
          return [] unless components

          raw = components.raw_schema
          return [] unless raw.is_a?(Hash) && raw.key?('pathItems')

          [violation(
            path: "#{components.object_reference}/pathItems",
            message: '`components.pathItems` is a 3.1 addition; 3.0 documents should not declare it',
          )]
        end
      end
    end
  end
end

module OpenAPIParser
  class SpecValidator
    module Rules
      # `components.mediaTypes` is a 3.2 addition. The parse layer accepts
      # it permissively; this rule reports the version mismatch.
      class MediaTypesBefore32 < Rule
        def check(root)
          return [] unless version_before?('3.2')

          components = root.components
          return [] unless components

          raw = components.raw_schema
          return [] unless raw.is_a?(Hash) && raw.key?('mediaTypes')

          [violation(
            path: "#{components.object_reference}/mediaTypes",
            message: '`components.mediaTypes` is a 3.2 addition; earlier documents should not declare it',
          )]
        end
      end
    end
  end
end

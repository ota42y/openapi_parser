module OpenAPIParser
  class SpecValidator
    module Rules
      # `$self` is a 3.2 root-level addition declaring the document's own
      # URI for reference resolution. The parse layer accepts it
      # permissively; this rule reports the version mismatch.
      class SelfBefore32 < Rule
        def check(root)
          return [] unless version_before?('3.2')
          return [] unless root.raw_schema.is_a?(Hash) && root.raw_schema.key?('$self')

          [violation(
            path: '#/$self',
            message: '`$self` is a 3.2 root-level addition; earlier documents have no such field',
          )]
        end
      end
    end
  end
end

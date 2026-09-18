module OpenAPIParser
  class SpecValidator
    module Rules
      # 3.2 adds `summary`, `parent`, and `kind` to the Tag Object.
      # Tags are not modeled by the parse layer, so this rule inspects the
      # raw root-level `tags` array.
      class TagFieldsBefore32 < Rule
        NEW_FIELDS = %w[summary parent kind].freeze

        def check(root)
          return [] unless version_before?('3.2')

          tags = root.raw_schema.is_a?(Hash) ? root.raw_schema['tags'] : nil
          return [] unless tags.is_a?(Array)

          violations = []
          tags.each_with_index do |tag, index|
            next unless tag.is_a?(Hash)

            NEW_FIELDS.each do |field|
              next unless tag.key?(field)

              violations << violation(
                path: "#/tags/#{index}/#{field}",
                message: "`#{field}` on a Tag Object is a 3.2 addition; earlier documents have no such field",
              )
            end
          end
          violations
        end
      end
    end
  end
end

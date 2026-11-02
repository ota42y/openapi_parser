module OpenAPIParser
  class SpecValidator
    module Rules
      # 3.2 adds `itemSchema`, `itemEncoding`, and `prefixEncoding` to the
      # Media Type Object for sequential media types (SSE, JSON Lines,
      # JSON Sequences), and lets an Encoding Object nest `encoding`,
      # `itemEncoding`, and `prefixEncoding`. The parse layer accepts
      # `itemSchema` permissively; this rule reports the version mismatch.
      # Media Types under a Parameter or Header `content` are not modeled,
      # so fields there are not reached.
      class StreamingFieldsBefore32 < Rule
        NEW_FIELDS = %w[itemSchema itemEncoding prefixEncoding].freeze
        NEW_ENCODING_FIELDS = %w[encoding itemEncoding prefixEncoding].freeze

        def check(root)
          return [] unless version_before?('3.2')

          violations = []
          each_node(root, OpenAPIParser::Schemas::MediaType) do |node|
            raw = node.raw_schema
            next unless raw.is_a?(Hash)

            NEW_FIELDS.each do |field|
              next unless raw.key?(field)

              violations << violation(
                path: "#{node.object_reference}/#{field}",
                message: "`#{field}` on a Media Type Object is a 3.2 addition; earlier documents have no such field",
              )
            end

            violations.concat(encoding_violations(node, raw['encoding']))
          end
          violations
        end

        private

          def encoding_violations(node, encodings)
            return [] unless encodings.is_a?(Hash)

            encodings.flat_map do |property, encoding|
              next [] unless encoding.is_a?(Hash)

              NEW_ENCODING_FIELDS.select { |field| encoding.key?(field) }.map do |field|
                violation(
                  path: "#{node.object_reference}/encoding/#{escape_reference(property)}/#{field}",
                  message: "`#{field}` on an Encoding Object is a 3.2 addition; earlier documents have no such field",
                )
              end
            end
          end
      end
    end
  end
end

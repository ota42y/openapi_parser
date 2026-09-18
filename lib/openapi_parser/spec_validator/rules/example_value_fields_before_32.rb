module OpenAPIParser
  class SpecValidator
    module Rules
      # 3.2 adds `dataValue` and `serializedValue` to the Example Object.
      # Example Objects are not modeled by the parse layer, so this rule
      # inspects the raw `examples` maps on Parameter, Media Type, and
      # Header objects, plus `components.examples`. Media Types under a
      # Parameter or Header `content` and anything under callbacks are not
      # modeled, so examples there are not reached.
      class ExampleValueFieldsBefore32 < Rule
        NEW_FIELDS = %w[dataValue serializedValue].freeze

        def check(root)
          return [] unless version_before?('3.2')

          violations = []
          node_classes = [
            OpenAPIParser::Schemas::Parameter,
            OpenAPIParser::Schemas::MediaType,
            OpenAPIParser::Schemas::Header,
            OpenAPIParser::Schemas::Components,
          ]
          each_node(root, *node_classes) do |node|
            raw = node.raw_schema
            next unless raw.is_a?(Hash)

            examples = raw['examples']
            next unless examples.is_a?(Hash)

            examples.each do |name, example|
              next unless example.is_a?(Hash)

              NEW_FIELDS.each do |field|
                next unless example.key?(field)

                violations << violation(
                  path: "#{node.object_reference}/examples/#{escape_reference(name)}/#{field}",
                  message: "`#{field}` on an Example Object is a 3.2 addition; earlier documents have no such field",
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

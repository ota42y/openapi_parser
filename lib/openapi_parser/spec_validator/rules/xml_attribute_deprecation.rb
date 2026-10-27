module OpenAPIParser
  class SpecValidator
    module Rules
      # 3.2 deprecates `attribute: true` on the XML Object in favor of
      # `nodeType: attribute`. The field is still allowed but discouraged,
      # so we report it as a violation on 3.2 documents.
      class XmlAttributeDeprecation < Rule
        def check(root)
          return [] unless version_at_least?('3.2')

          violations = []
          each_schema(root) do |schema|
            raw = schema.raw_schema
            next unless raw.is_a?(Hash)

            xml = raw['xml']
            next unless xml.is_a?(Hash) && xml['attribute'] == true

            violations << violation(
              path: schema.object_reference,
              message: '`attribute` on an XML Object is deprecated in 3.2; use `nodeType: attribute`',
            )
          end
          violations
        end
      end
    end
  end
end

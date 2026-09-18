module OpenAPIParser
  class SpecValidator
    module Rules
      # 3.2 adds `nodeType` to the XML Object (replacing `attribute` and
      # `wrapped`). XML Objects are not modeled by the parse layer, so this
      # rule inspects the raw `xml` field on schemas.
      class XmlNodeTypeBefore32 < Rule
        def check(root)
          return [] unless version_before?('3.2')

          violations = []
          each_schema(root) do |schema|
            raw = schema.raw_schema
            next unless raw.is_a?(Hash)

            xml = raw['xml']
            next unless xml.is_a?(Hash) && xml.key?('nodeType')

            violations << violation(
              path: schema.object_reference,
              message: '`nodeType` on an XML Object is a 3.2 addition; earlier documents have no such field',
            )
          end
          violations
        end
      end
    end
  end
end

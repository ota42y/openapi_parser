module OpenAPIParser
  class SpecValidator
    module Rules
      # `style: cookie` is a 3.2 Parameter style for cookie serialization.
      # Runtime validation ignores `style`; this rule reports the version
      # mismatch.
      class CookieStyleBefore32 < Rule
        def check(root)
          return [] unless version_before?('3.2')

          violations = []
          each_node(root, OpenAPIParser::Schemas::Parameter) do |node|
            raw = node.raw_schema
            next unless raw.is_a?(Hash) && raw['style'] == 'cookie'

            violations << violation(
              path: "#{node.object_reference}/style",
              message: '`style: cookie` is a 3.2 Parameter style; earlier documents have no such style',
            )
          end
          violations
        end
      end
    end
  end
end

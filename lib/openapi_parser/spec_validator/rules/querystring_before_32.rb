module OpenAPIParser
  class SpecValidator
    module Rules
      # `in: querystring` is a 3.2 Parameter location that treats the whole
      # query string as one value described by `content`. Runtime validation
      # does not support it yet; this rule reports the version mismatch.
      class QuerystringBefore32 < Rule
        def check(root)
          return [] unless version_before?('3.2')

          violations = []
          each_node(root, OpenAPIParser::Schemas::Parameter) do |node|
            raw = node.raw_schema
            next unless raw.is_a?(Hash) && raw['in'] == 'querystring'

            violations << violation(
              path: "#{node.object_reference}/in",
              message: '`in: querystring` is a 3.2 Parameter location; earlier documents have no such location',
            )
          end
          violations
        end
      end
    end
  end
end

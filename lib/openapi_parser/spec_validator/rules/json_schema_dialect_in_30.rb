module OpenAPIParser
  class SpecValidator
    module Rules
      # `jsonSchemaDialect` is a 3.1 root-level addition; 3.0 has no
      # equivalent.
      class JsonSchemaDialectIn30 < Rule
        def check(root)
          return [] unless version == :v3_0
          return [] unless root.raw_schema.is_a?(Hash) && root.raw_schema.key?('jsonSchemaDialect')

          [violation(
            path: '#/jsonSchemaDialect',
            message: '`jsonSchemaDialect` is a 3.1 root-level addition; 3.0 documents have no such field',
          )]
        end
      end
    end
  end
end

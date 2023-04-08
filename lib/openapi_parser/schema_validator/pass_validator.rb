class OpenAPIParser::SchemaValidator
  class PassValidator < Base
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema, **_keyword_args)
      [value, nil]
    end
  end
end

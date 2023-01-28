class OpenAPIParser::SchemaValidator
  class NotValidator < Base
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema, **_keyword_args)
      coerced, err = validatable.validate_schema(value, schema.not)

      if err
        [coerced, nil]
      else
        [nil, OpenAPIParser::NotNot.new(value, schema.object_reference)]
      end
    end
  end
end

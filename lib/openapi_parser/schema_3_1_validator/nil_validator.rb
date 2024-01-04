class OpenAPIParser::Schema31Validator
  class NilValidator < Base
    # @param [Object] value
    # @param [OpenAPIParser::Schemas31Schema] schema
    def coerce_and_validate(value, schema, **_keyword_args)
      return [value, nil] if schema.nullable

      [nil, OpenAPIParser::NotNullError.new(schema.object_reference)]
    end
  end
end

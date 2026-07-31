class OpenAPIParser::SchemaValidator
  class NilValidator < Base
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema, **_keyword_args)
      return [value, nil] if schema.nullable
      # 3.1: `type: "null"` makes nil the only valid value for the schema.
      return [value, nil] if schema.type == 'null'

      [nil, OpenAPIParser::NotNullError.new(schema.object_reference)]
    end
  end
end

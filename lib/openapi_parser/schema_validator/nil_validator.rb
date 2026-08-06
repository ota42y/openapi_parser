class OpenAPIParser::SchemaValidator
  class NilValidator < Base
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema, **_keyword_args)
      return [value, nil] if schema.nullable
      # 3.1: `type: "null"` makes nil the only valid value for the schema.
      return [value, nil] if schema.type == 'null'
      # 3.1: `type: [..., "null"]` lets nil coexist with another primitive.
      return [value, nil] if schema.type.is_a?(Array) && schema.type.include?('null')

      [nil, OpenAPIParser::NotNullError.new(schema.object_reference)]
    end
  end
end

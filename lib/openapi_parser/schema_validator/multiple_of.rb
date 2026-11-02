class OpenAPIParser::SchemaValidator
  module MultipleOf
    # check multipleOf by schema
    # @param [Numeric] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def check_multiple_of(value, schema)
      multiple_of = schema.multipleOf
      return [value, nil] unless multiple_of
      return [value, nil] if (value % multiple_of).zero?

      [nil, OpenAPIParser::NotMultipleOf.new(value, multiple_of, schema.object_reference)]
    end
  end
end

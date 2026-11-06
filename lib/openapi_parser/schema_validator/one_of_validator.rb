class OpenAPIParser::SchemaValidator
  class OneOfValidator < Base
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema, **_keyword_args)
      if value.nil? && schema.nullable
        return [value, nil]
      end
      if schema.discriminator
        return validate_discriminator_schema(schema.discriminator, value, candidate_schemas: schema.one_of)
      end

      # if multiple schemas are satisfied, it's not valid
      matched = schema.one_of.map { |s| validatable.validate_schema(value, s) }.select { |_coerced, err| err.nil? }
      if matched.one?
        [matched.first.first, nil]
      else
        [nil, OpenAPIParser::NotOneOf.new(value, schema.object_reference)]
      end
    end
  end
end

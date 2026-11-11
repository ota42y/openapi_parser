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

      # A value that matches a member as it is does not need coercion. Coercion
      # could make it match other members too, like "1" for [integer, string].
      if @coerce_value
        literal_matches = schema.one_of.select { |s| validatable.valid_without_coercion?(value, s) }
        return validatable.validate_schema(value, literal_matches.first) if literal_matches.one?
        return [nil, OpenAPIParser::NotOneOf.new(value, schema.object_reference)] if literal_matches.size > 1
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

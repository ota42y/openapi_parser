class OpenAPIParser::SchemaValidator
  class AnyOfValidator < Base
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema, **_keyword_args)
      if value.nil? && legacy_nullable?(schema)
        return [value, nil]
      end
      discriminator = schema.discriminator
      if discriminator && !schema.root.use_3_1_features?
        return validate_discriminator_schema(discriminator, value, candidate_schemas: schema.any_of)
      end

      errors = {} if discriminator
      schema.any_of.each do |s|
        coerced, err = validatable.validate_schema(value, s)
        return [coerced, nil] if err.nil?

        errors[s] = err if errors
      end
      error = discriminator_member_error(discriminator, value, errors) if errors
      [nil, error || OpenAPIParser::NotAnyOf.new(value, schema.object_reference)]
    end
  end
end

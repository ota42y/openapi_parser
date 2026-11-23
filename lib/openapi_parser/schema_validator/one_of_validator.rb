class OpenAPIParser::SchemaValidator
  class OneOfValidator < Base
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema, **_keyword_args)
      if value.nil? && schema.nullable
        return [value, nil]
      end
      discriminator = schema.discriminator
      if discriminator && !schema.root.use_3_1_features?
        return validate_discriminator_schema(discriminator, value, candidate_schemas: schema.one_of)
      end

      # A value that matches a member as it is does not need coercion. Coercion
      # could make it match other members too, like "1" for [integer, string].
      if @coerce_value
        literal_matches = schema.one_of.select { |s| validatable.valid_without_coercion?(value, s) }
        return validatable.validate_schema(value, literal_matches.first) if literal_matches.one?
        return [nil, OpenAPIParser::NotOneOf.new(value, schema.object_reference)] if literal_matches.size > 1
      end

      results = schema.one_of.map { |s| validatable.validate_schema(value, s) }
      matched = results.select { |_coerced, err| err.nil? }
      return [matched.first.first, nil] if matched.one?

      if discriminator && matched.empty?
        errors = schema.one_of.zip(results.map(&:last)).to_h
        error = discriminator_member_error(discriminator, value, errors)
      end
      [nil, error || OpenAPIParser::NotOneOf.new(value, schema.object_reference)]
    end
  end
end

class OpenAPIParser::Schema31Validator
  class OneOfValidator < Base
    # @param [Object] value
    # @param [OpenAPIParser::Schemas31Schema] schema
    def coerce_and_validate(value, schema, **_keyword_args)
      if value.nil? && schema.nullable
        return [value, nil]
      end
      if schema.discriminator
        return validate_discriminator_schema(schema.discriminator, value)
      end

      # if multiple schemas are satisfied, it's not valid
      result = schema.one_of.one? do |s|
        _coerced, err = validatable.validate_schema(value, s)
        err.nil?
      end
      if result
        [value, nil]
      else
        [nil, OpenAPIParser::NotOneOf.new(value, schema.object_reference)]
      end
    end
  end
end

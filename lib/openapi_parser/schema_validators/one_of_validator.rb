class OpenAPIParser::SchemaValidator
  class OneOfValidator < Base
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema, **_keyword_args)
      if schema.discriminator
        return validate_discriminator_schema(schema.discriminator, value)
      end

      # if multiple schemas are satisfied, it's not valid
      result = schema.one_of.to_enum(:one?).with_index do |s, i|
        _coerced, err = validatable.frame(i) do
          validatable.validate_schema(value, s)
        end
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

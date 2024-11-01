class OpenAPIParser::SchemaValidator
  class FloatValidator < Base
    include ::OpenAPIParser::SchemaValidator::Enumable
    include ::OpenAPIParser::SchemaValidator::MinimumMaximum

    # validate float value by schema
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema, **_keyword_args)
      value = coerce(value) if @options.coerce_value

      return validatable.validate_integer(value, schema) if value.kind_of?(Integer)

      coercer_and_validate_numeric(value, schema)
    end

    private

      def coercer_and_validate_numeric(value, schema)
        return OpenAPIParser::ValidateError.build_error_result(value, schema, options: @options) unless value.kind_of?(Numeric)

        value, err = check_enum_include(value, schema)
        return [nil, err] if err

        check_minimum_maximum(value, schema)
      end

      def coerce(value)
        Float(value)
      rescue ArgumentError, TypeError
        value
      end
  end
end

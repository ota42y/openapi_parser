class OpenAPIParser::SchemaValidator
  class IntegerValidator < Base
    include ::OpenAPIParser::SchemaValidator::Enumable
    include ::OpenAPIParser::SchemaValidator::MinimumMaximum
    include ::OpenAPIParser::SchemaValidator::MultipleOf

    # validate integer value by schema
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema, **_keyword_args)
      value = coerce(value) if @coerce_value

      return OpenAPIParser::ValidateError.build_error_result(value, schema) unless integer?(value, schema)

      value, err = check_enum_include(value, schema)
      return [nil, err] if err

      value, err = check_multiple_of(value, schema)
      return [nil, err] if err

      check_minimum_maximum(value, schema)
    end

    # 3.1 follows JSON Schema, where 1.0 is an integer. 3.0 defines an
    # integer as a number without a fraction, so 1.0 is not one there.
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    # @return [Boolean]
    def integer?(value, schema)
      return true if value.kind_of?(Integer)
      return false unless value.kind_of?(Float) && value.finite? && value == value.floor

      schema.root.use_3_1_features?
    end

    private

      def coerce(value)
        return value if value.kind_of?(Integer)
        # Integer() truncates a Float, so convert only one with no fractional part.
        return value.finite? && value == value.floor ? value.to_i : value if value.kind_of?(Float)

        begin
          Integer(value)
        rescue ArgumentError, TypeError
          value
        end
      end
  end
end

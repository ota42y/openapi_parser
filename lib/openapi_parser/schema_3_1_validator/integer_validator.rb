class OpenAPIParser::Schema31Validator
  class IntegerValidator < Base
    include ::OpenAPIParser::Schema31Validator::Enumable
    include ::OpenAPIParser::Schema31Validator::MinimumMaximum

    # validate integer value by schema
    # @param [Object] value
    # @param [OpenAPIParser::Schemas31Schema] schema
    def coerce_and_validate(value, schema, **_keyword_args)
      value = coerce(value) if @coerce_value

      return OpenAPIParser::ValidateError.build_error_result(value, schema) unless value.kind_of?(Integer)

      value, err = check_enum_include(value, schema)
      return [nil, err] if err

      check_minimum_maximum(value, schema)
    end

    private

      def coerce(value)
        return value if value.kind_of?(Integer)

        begin
          Integer(value)
        rescue ArgumentError, TypeError
          value
        end
      end
  end
end

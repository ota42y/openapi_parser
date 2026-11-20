class OpenAPIParser::SchemaValidator
  # 3.1: `if` picks the schema to check the value with.
  # A value valid against `if` is checked with `then`, and any other value with `else`.
  # `if` itself never makes the value invalid.
  class IfThenElseValidator < Base
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema, **_keyword_args)
      return [value, nil] unless schema.if_schema

      if_value, if_error = validatable.validate_schema(value, schema.if_schema)
      if if_error
        return [value, nil] unless schema.else_schema

        return validatable.validate_schema(value, schema.else_schema)
      end

      # `then` sees the value coerced by `if`. A coerced value of another class,
      # like DateTime, is only the output form, so `then` checks the original value.
      then_value = json_value?(if_value) ? if_value : value
      return [then_value, nil] unless schema.then_schema

      validatable.validate_schema(then_value, schema.then_schema)
    end

    private

      def json_value?(value)
        OpenAPIParser::SchemaValidator::JSON_VALUE_CLASSES.any? { |klass| value.is_a?(klass) }
      end
  end
end

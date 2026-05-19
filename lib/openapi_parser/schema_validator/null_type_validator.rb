class OpenAPIParser::SchemaValidator
  # Validates schemas declared as `type: "null"` (3.1) against non-nil
  # values. The nil case is short-circuited by NilValidator before this
  # validator is even picked up.
  class NullTypeValidator < Base
    def coerce_and_validate(value, schema, **_keyword_args)
      OpenAPIParser::ValidateError.build_error_result(value, schema)
    end
  end
end

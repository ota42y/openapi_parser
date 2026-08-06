class OpenAPIParser::SchemaValidator
  # Emits a ValidateError unconditionally. Used when the dispatcher has
  # already decided that no primitive applies to the value, e.g.:
  # - schema declares `type: "null"` and the value is non-nil (3.1)
  # - schema declares `type: [t1, t2, ...]` and the value matches none
  class TypeMismatchValidator < Base
    def coerce_and_validate(value, schema, **_keyword_args)
      OpenAPIParser::ValidateError.build_error_result(value, schema)
    end
  end
end

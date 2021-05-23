class OpenAPIParser::SchemaValidator
  class UnspecifiedTypeValidator < Base
    # @param [Object] value
    def coerce_and_validate(value, _schema, **_keyword_args)
      value
    end
  end
end

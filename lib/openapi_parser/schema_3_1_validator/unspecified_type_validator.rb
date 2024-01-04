class OpenAPIParser::Schema31Validator
  class UnspecifiedTypeValidator < Base
    # @param [Object] value
    def coerce_and_validate(value, _schema, **_keyword_args)
      [value, nil]
    end
  end
end

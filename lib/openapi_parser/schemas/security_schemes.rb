module OpenAPIParser::Schemas
  class SecurityScheme < Base
    # @!attribute [r] jwt
    #   @return [Jwt, nil]
    openapi_attr_object :jwt, Jwt, reference: false

    # validate by jwt
    # @param [Object] value
    def validate(value)
      OpenAPIParser::SchemaValidator.validate(value, jwt, OpenAPIParser::SchemaValidator::Options.new)
    end
  end
end

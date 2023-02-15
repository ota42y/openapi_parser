module OpenAPIParser::Schemas
  class SecurityScheme < Base
    # @!attribute [r] jwt
    #   @return [Jwt, nil]
    openapi_attr_object :jwt, Jwt, reference: false

  end
end

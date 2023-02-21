module OpenAPIParser::Schemas
  class SecuritySchemes < Base

    openapi_attr_values :type, :description, :scheme
    openapi_attr_value :bearer_format, schema_key: :bearerFormat

    def validate_security_schemes(securityScheme)
      if self.type == "http" && self.scheme == "bearer" && self.bearer_format == "JWT"
        # check if the JWT token is being sent and try to decode.
        # if JWT token does not exist or token cannot decode, then deny access
        puts "Checks is done"
      end
    end
  end
end

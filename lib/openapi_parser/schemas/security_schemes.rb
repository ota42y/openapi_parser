module OpenAPIParser::Schemas
  class SecuritySchemes < Base

    openapi_attr_values :type, :description, :scheme
    openapi_attr_value :bearer_format, schema_key: :bearerFormat

    def validate_security_schemes(security)
      puts "Validation code is executing!"
      if self.type == "http" && self.scheme == "bearer" && self.bearer_format == "JWT"
        # check if the JWT token is being sent and try to decode.
        # if JWT token does not exist or token cannot decode, then deny access
      end
    end
  end
end

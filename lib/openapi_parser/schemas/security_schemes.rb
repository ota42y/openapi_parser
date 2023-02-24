require 'jwt'
module OpenAPIParser::Schemas
  class SecuritySchemes < Base

    openapi_attr_values :type, :description, :scheme
    openapi_attr_value :bearer_format, schema_key: :bearerFormat

    def validate_security_schemes(securityScheme, headers)
      if self.type == "http" && self.scheme == "bearer" && self.bearer_format == "JWT"
        raise "need authorization" unless headers["AUTHORIZATION"]
        raise "not bearer" unless headers["AUTHORIZATION"].split[0] == "Bearer"

        # check if the JWT token is being sent and try to decode.
        # if JWT token does not exist or token cannot decode, then deny access
        token = headers["AUTHORIZATION"].split[1]
        JWT.decode token, nil, false
      end
    end
  end
end

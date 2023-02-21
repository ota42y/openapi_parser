module OpenAPIParser::Schemas
  class SecuritySchemes < Base

    openapi_attr_values :type, :description, :schema
    openapi_attr_value :bearer_format, schema_key: :bearerFormat

    def validate_security_schemes(params, options)
      if self.type == "http" && self.schema == "bearer" && self.bearer_format == "JWT"
        puts "YAY!"
      end
    end
  end
end

module OpenAPIParser::Schemas
  class Jwt < Base
    # @!attribute [r] type 
    #   @return [String, nil]
    # @!attribute [r] scheme
    #   @return [String, nil] 
    # @!attribute [r] bearerFormat
    #   @return [String, nil]

    openapi_attr_values :type, :scheme,
                        :bearerFormat
  end
end

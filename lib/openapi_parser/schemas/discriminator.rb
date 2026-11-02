module OpenAPIParser::Schemas
  class Discriminator < Base
    # @!attribute [r] property_name
    #   @return [String, nil]
    openapi_attr_value :property_name, schema_key: :propertyName

    # @!attribute [r] mapping
    #   @return [Hash{String => String]
    openapi_attr_value :mapping

    # @!attribute [r] default_mapping
    #   @return [String, nil] fallback schema name or reference (OpenAPI 3.2+)
    openapi_attr_value :default_mapping, schema_key: :defaultMapping
  end
end

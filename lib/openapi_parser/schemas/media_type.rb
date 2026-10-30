# TODO: example
# TODO: examples
# TODO: encoding

module OpenAPIParser::Schemas
  class MediaType < Base
    # @!attribute [r] schema
    #   @return [Schema, nil] OpenAPI3 Schema object
    openapi_attr_object :schema, Schema, reference: true

    # @!attribute [r] item_schema
    #   @return [Schema, nil] schema for each item of a sequential media type (OpenAPI 3.2+); not yet used for validation
    openapi_attr_object :item_schema, Schema, reference: true, schema_key: :itemSchema

    # validate params by schema definitions
    # @param [Hash] params
    # @param [OpenAPIParser::SchemaValidator::Options] options
    def validate_parameter(params, options)
      OpenAPIParser::SchemaValidator.validate(params, schema, options)
    end
  end
end

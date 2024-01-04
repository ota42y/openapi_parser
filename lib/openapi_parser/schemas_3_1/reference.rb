module OpenAPIParser::Schemas31
  class Reference < Base
    # @!attribute [r] ref
    #   @return [Base]
    openapi_attr_value :ref, schema_key: '$ref'
  end
end

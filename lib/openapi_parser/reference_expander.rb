class OpenAPIParser::ReferenceExpander
  class << self
    # @param [OpenAPIParser::Schemas::OpenAPI] openapi
    def expand(openapi, validate_references)
      openapi.expand_reference(openapi, validate_references)
      openapi.purge_object_cache
    end
  end
end

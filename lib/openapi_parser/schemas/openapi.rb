# TODO: info object
# TODO: servers object
# TODO: tags object
# TODO: externalDocs object
# TODO: support schema definition check

module OpenAPIParser::Schemas
  class OpenAPI < Base
    def initialize(raw_schema, config)
      super('#', nil, self, raw_schema)
      @find_object_cache = {}
      @path_item_finder = OpenAPIParser::PathItemFinder.new(paths) if paths # invalid definition
      @config = config
    end

    # @!attribute [r] openapi
    #   @return [String, nil]
    openapi_attr_value :openapi, data_types: [String], required: true

    # @!attribute [r] paths
    #   @return [Paths, nil]
    openapi_attr_object :paths, Paths, reference: false, required: true

    # @!attribute [r] components
    #   @return [Components, nil]
    openapi_attr_object :components, Components, reference: false

    # @return [OpenAPIParser::RequestOperation, nil]
    def request_operation(http_method, request_path)
      OpenAPIParser::RequestOperation.create(http_method, request_path, @path_item_finder, @config)
    end

    def valid_definition?
      openapi_definition_errors.empty?
    end

    def openapi_definition_errors
      @openapi_definition_errors ||= validate_definitions([])
    end
  end
end

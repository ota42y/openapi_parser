# TODO: info object
# TODO: servers object
# TODO: tags object
# TODO: externalDocs object

module OpenAPIParser::Schemas
  class OpenAPI < Base
    # @param [OpenAPIParser::Schemas::OpenAPI, nil] referrer the document whose $ref loads this one
    def initialize(raw_schema, config, uri: nil, schema_registry: {}, referrer: nil)
      # set before super: child objects consult use_3_2_features? while they're built
      @config = config
      @referrer = referrer
      super('#', nil, self, raw_schema)
      @find_object_cache = {}
      @path_item_finder = OpenAPIParser::PathItemFinder.new(paths) if paths # invalid definition
      @uri = uri
      @schema_registry = schema_registry

      # schema_registery is shared among schemas, and prevents a schema from being loaded multiple times
      schema_registry[uri] = self if uri
    end

    # @!attribute [r] openapi
    #   @return [String, nil]
    openapi_attr_values :openapi

    # Declared OpenAPI version as a comparable value.
    # A prerelease tag is dropped ("3.1.0-rc1" => 3.1.0) because it does not
    # change which version's rules the document is written against.
    # @return [Gem::Version, nil] nil when the field is missing or not a
    #   major.minor[.patch] version string
    def openapi_version
      return nil unless openapi.is_a?(String)
      return nil unless openapi.match?(/\A\d+\.\d+/) && Gem::Version.correct?(openapi)

      Gem::Version.new(openapi).release
    end

    # Whether OpenAPI 3.2 runtime behavior applies: the document declares 3.2
    # or later, or the allow_3_2_features config is set. A referenced file
    # that declares no version follows the document that loaded it.
    # @return [Boolean]
    def use_3_2_features?
      return true if @config.allow_3_2_features

      version = openapi_version
      return version >= Gem::Version.new('3.2') if version
      return @referrer.use_3_2_features? if openapi.nil? && @referrer

      false
    end

    # @!attribute [r] paths
    #   @return [Paths, nil]
    openapi_attr_object :paths, Paths, reference: false

    # @!attribute [r] components
    #   @return [Components, nil]
    openapi_attr_object :components, Components, reference: false

    # @!attribute [r] info
    #   @return [Info, nil]
    openapi_attr_object :info, Info, reference: false

    # @!attribute [r] webhooks
    #   @return [Hash{String => PathItem}, nil] webhook path items (OpenAPI 3.1+)
    openapi_attr_hash_object :webhooks, PathItem, reference: true

    # @!attribute [r] json_schema_dialect
    #   @return [String, nil] dialect URI for embedded JSON Schemas (OpenAPI 3.1+)
    openapi_attr_value :json_schema_dialect, schema_key: :jsonSchemaDialect

    # @!attribute [r] self_uri
    #   @return [String, nil] the document's own URI, `$self` (OpenAPI 3.2+)
    openapi_attr_value :self_uri, schema_key: :'$self'

    # @return [OpenAPIParser::RequestOperation, nil]
    def request_operation(http_method, request_path)
      OpenAPIParser::RequestOperation.create(http_method, request_path, @path_item_finder, @config)
    end

    # load another schema with shared config and schema_registry
    # @return [OpenAPIParser::Schemas::OpenAPI]
    def load_another_schema(uri)
      resolved_uri = resolve_uri(uri)
      return if resolved_uri.nil?

      loaded = @schema_registry[resolved_uri]
      return loaded if loaded

      OpenAPIParser.load_uri(resolved_uri, config: @config, schema_registry: @schema_registry, referrer: self)
    end

    private

      def resolve_uri(uri)
        if uri.absolute?
          uri
        else
          @uri&.merge(uri)
        end
      end
  end
end

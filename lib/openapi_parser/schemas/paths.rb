# TODO: support schema definition check

module OpenAPIParser::Schemas
  class Paths < Base
    # @!attribute [r] path
    #   @return [Hash{String => PathItem, Reference}, nil]
    openapi_attr_hash_body_objects 'path', PathItem, allow_reference: false, allow_data_type: false

    def path_item_to_path_template_data
      return @path_item_to_path_template_data  if defined?(@path_item_to_path_template_data)

      path_sets = path.map { |k, v| [v, k.split('/').select { |path_name| OpenAPIParser::PathItemFinder.path_template?(path_name) }.to_set] }

      @path_item_to_path_template_data = path_sets.to_h
    end
  end
end

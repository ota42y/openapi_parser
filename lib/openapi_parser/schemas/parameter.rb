# TODO: support examples
# TODO: support schema definition check

module OpenAPIParser::Schemas
  # Parameter Object in OpenAPI3
  class Parameter < Base
    openapi_attr_value :name, definition_validation_method_name: :name_definition
    openapi_attr_values :in, :description, :required, :deprecated, :style, :explode, :example

    openapi_attr_value :allow_empty_value, schema_key: :allowEmptyValue
    openapi_attr_value :allow_reserved, schema_key: :allowReserved

    # @!attribute [r] schema
    #   @return [Schema, Reference, nil]
    openapi_attr_object :schema, Schema, reference: true

    # @return [Object] coerced or original params
    # @param [OpenAPIParser::SchemaValidator::Options] options
    def validate_params(params, options)
      ::OpenAPIParser::SchemaValidator.validate(params, schema, options)
    end

    # @param [Array<OpenAPIParser::Schemas::Base>] parents
    def name_definition(reference, parents)
      return OpenAPIParser::InvalidDefinitionError.new(reference, 'name', name) if name.nil?

      return check_name_in_path(reference, parents) if self.in == 'path'

      nil
    end

    private

      def check_name_in_path(reference, parents)
        paths, path_item = find_paths_and_path_item(parents)
        templates = paths.path_item_to_path_template_data[path_item]

        return nil if templates.include?("{#{name}}")

        OpenAPIParser::InvalidPathTemplateNameError.new(reference, 'name', name)
      end

      # @param [Array<OpenAPIParser::Schemas::Base>] parents
      def find_paths_and_path_item(parents)
        path_item = nil
        paths = nil
        parents.each do |s|
          path_item = s if s.kind_of?(PathItem)
          paths = s if s.kind_of?(Paths)
        end

        return paths, path_item
      end
  end
end

# loader base class for create OpenAPI::Schemas::Base object
class OpenAPIParser::SchemaLoader::Creator < OpenAPIParser::SchemaLoader::Base
  # @param [String] variable_name
  # @param [Hash] options
  def initialize(variable_name, options)
    super(variable_name, options)

    @klass = options[:klass]
    @allow_reference = options[:reference] || false
    @allow_data_type = options[:allow_data_type]
  end

  private

    attr_reader :klass, :allow_reference, :allow_data_type

    # @return Boolean
    def check_reference_schema?(check_schema)
      check_object_schema?(check_schema) && !check_schema['$ref'].nil?
    end

    def check_object_schema?(check_schema)
      check_schema.kind_of?(::Hash)
    end

    def build_openapi_object_from_option(target_object, ref, schema)
      return nil unless schema

      if @allow_data_type && !check_object_schema?(schema)
        schema
      elsif @allow_reference && check_reference_schema?(schema)
        OpenAPIParser::Schemas::Reference.new(ref, target_object, target_object.root, schema)
      else
        @klass.new(ref, target_object, target_object.root, schema)
      end
    end

    def create_data_types
      return @create_data_types if defined? @create_data_types

      # TODO: check allow reference
      @create_data_types = [@klass]
      @create_data_types.concat(@data_types) if @allow_data_type && @data_types
      @create_data_types
    end
end

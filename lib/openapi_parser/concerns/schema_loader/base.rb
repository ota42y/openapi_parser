# loader base class
class OpenAPIParser::SchemaLoader::Base
  # @param [String] variable_name
  # @param [Hash] options
  def initialize(variable_name, options)
    @variable_name = variable_name
    @schema_key = options[:schema_key] || variable_name
    @data_types = options[:data_types]
    @required = options[:required]
    @definition_validation_method_name = options[:definition_validation_method_name]
  end

  # @param [OpenAPIParser::Schemas::Base] _target_object
  # @param [Hash] _raw_schema
  # @return [Array<OpenAPIParser::Schemas::Base>, nil]
  def load_data(_target_object, _raw_schema)
    raise 'need implement'
  end

  # @param [Array<OpenAPIParser::Schemas::Base>] _parents
  # @param [OpenAPIParser::Schemas::Base] _target_object
  # @return [Array<OpenAPIParser::InvalidDefinitionError>]
  def definition_validate(_parents, _target_object)
    # raise 'need_implement'
    []
  end

  private

    attr_reader :variable_name, :schema_key

    # create instance variable @variable_name using data
    # @param [OpenAPIParser::Schemas::Base] target
    # @param [String] variable_name
    # @param [Object] data
    def variable_set(target, variable_name, data)
      target.instance_variable_set("@#{variable_name}", data)
    end

    def build_object_reference_from_base(base, names)
      names = [names] unless names.kind_of?(Array)
      ref = names.map { |n| escape_reference(n) }.join('/')

      "#{base}/#{ref}"
    end

    def escape_reference(str)
      str.to_s.gsub('/', '~1')
    end

    def valid_definition?(target_object, reference, name, data, parents, allow_data_types) # rubocop:disable Metrics/ParameterLists
      return target_object.send(@definition_validation_method_name, reference, parents) if @definition_validation_method_name

      return nil unless allow_data_types

      return nil if data.nil? && !@required

      return nil if allow_data_types.any? { |type| data.kind_of?(type) }

      OpenAPIParser::InvalidDefinitionError.new(reference, name, data)
    end
end

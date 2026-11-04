# loader base class for create OpenAPI::Schemas::Base object
class OpenAPIParser::SchemaLoader::Creator < OpenAPIParser::SchemaLoader::Base
  # these do not change validation, so a `$ref` with only these stays a Reference
  REF_ANNOTATIONS = %w[$ref $comment title description summary deprecated default example examples readOnly writeOnly].freeze

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

    def build_object_reference_from_base(base, names)
      names = [names] unless names.kind_of?(Array)
      ref = names.map { |n| escape_reference(n) }.join('/')

      "#{base}/#{ref}"
    end

    # @return Boolean
    def check_reference_schema?(check_schema)
      check_object_schema?(check_schema) && !check_schema['$ref'].nil?
    end

    # `reference:` is a Boolean, or a Proc taking the owning object
    def allow_reference?(target_object)
      @allow_reference.respond_to?(:call) ? @allow_reference.call(target_object) : @allow_reference
    end

    def check_object_schema?(check_schema)
      check_schema.kind_of?(::Hash)
    end

    # 3.1: a Schema Object applies the keywords next to `$ref`. A Reference Object,
    # and any object in 3.0, ignores them.
    def reference_class(target_object, schema)
      return OpenAPIParser::Schemas::Reference unless @klass == OpenAPIParser::Schemas::Schema && target_object.root.use_3_1_features?
      return OpenAPIParser::Schemas::Reference unless schema.keys.any? { |key| !REF_ANNOTATIONS.include?(key) && !key.start_with?('x-') }

      OpenAPIParser::Schemas::SchemaWithRef
    end

    def escape_reference(str)
      str.to_s.gsub('~', '~0').gsub('/', '~1')
    end

    def build_openapi_object_from_option(target_object, ref, schema)
      return nil if schema.nil?

      if @allow_data_type && !check_object_schema?(schema)
        schema
      elsif allow_reference?(target_object) && check_reference_schema?(schema)
        reference_class(target_object, schema).new(ref, target_object, target_object.root, schema)
      else
        @klass.new(ref, target_object, target_object.root, schema)
      end
    end
end

require_relative 'spec_validator/spec_violation'
require_relative 'spec_validator/rule'
require_relative 'spec_validator/rules/exclusive_minimum'
require_relative 'spec_validator/rules/exclusive_maximum'
require_relative 'spec_validator/rules/content_encoding_in_30'
require_relative 'spec_validator/rules/content_media_type_in_30'
require_relative 'spec_validator/rules/prefix_items_in_30'
require_relative 'spec_validator/rules/boolean_schema_in_30'
require_relative 'spec_validator/rules/json_schema_dialect_in_30'
require_relative 'spec_validator/rules/type_array_in_30'
require_relative 'spec_validator/rules/path_items_in_30'
require_relative 'spec_validator/rules/nullable_deprecation'
require_relative 'spec_validator/rules/example_singular_deprecation'
require_relative 'spec_validator/rules/type_null_in_30'
require_relative 'spec_validator/rules/webhooks_in_30'
require_relative 'spec_validator/rules/const_in_30'
require_relative 'spec_validator/rules/dynamic_ref_in_30'
require_relative 'spec_validator/rules/dynamic_anchor_in_30'
require_relative 'spec_validator/rules/content_schema_in_30'
require_relative 'spec_validator/rules/xml_node_type_before_32'
require_relative 'spec_validator/rules/xml_attribute_deprecation'
require_relative 'spec_validator/rules/xml_wrapped_deprecation'
require_relative 'spec_validator/rules/media_types_before_32'
require_relative 'spec_validator/rules/server_name_before_32'
require_relative 'spec_validator/rules/self_before_32'
require_relative 'spec_validator/rules/tag_fields_before_32'
require_relative 'spec_validator/rules/example_value_fields_before_32'
require_relative 'spec_validator/rules/security_scheme_fields_before_32'

module OpenAPIParser
  class SpecViolationError < OpenAPIError
    attr_reader :violations

    def initialize(violations)
      @violations = violations
      super(nil)
    end

    def message
      @violations.map(&:to_s).join("\n")
    end
  end

  class SpecValidator
    def self.run(root)
      new(root).run
    end

    def self.run!(root, policy:)
      return if policy == :silent

      violations = run(root)
      return if violations.empty?

      case policy
      when :warn
        violations.each { |v| warn(v.to_s) }
      when :raise
        raise OpenAPIParser::SpecViolationError.new(violations)
      end
    end

    def initialize(root)
      @root = root
      @version = root.openapi_version
    end

    def run
      rules.flat_map { |klass| klass.new(@version).check(@root) }
    end

    private

      def rules
        [
          Rules::ExclusiveMinimum,
          Rules::ExclusiveMaximum,
          Rules::ContentEncodingIn30,
          Rules::ContentMediaTypeIn30,
          Rules::PrefixItemsIn30,
          Rules::BooleanSchemaIn30,
          Rules::JsonSchemaDialectIn30,
          Rules::TypeArrayIn30,
          Rules::PathItemsIn30,
          Rules::NullableDeprecation,
          Rules::ExampleSingularDeprecation,
          Rules::TypeNullIn30,
          Rules::WebhooksIn30,
          Rules::ConstIn30,
          Rules::DynamicRefIn30,
          Rules::DynamicAnchorIn30,
          Rules::ContentSchemaIn30,
          Rules::XmlNodeTypeBefore32,
          Rules::XmlAttributeDeprecation,
          Rules::XmlWrappedDeprecation,
          Rules::MediaTypesBefore32,
          Rules::ServerNameBefore32,
          Rules::SelfBefore32,
          Rules::TagFieldsBefore32,
          Rules::ExampleValueFieldsBefore32,
          Rules::SecuritySchemeFieldsBefore32,
        ]
      end
  end
end

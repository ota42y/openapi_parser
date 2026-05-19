require_relative 'spec_validator/spec_violation'
require_relative 'spec_validator/rule'
require_relative 'spec_validator/rules/exclusive_minimum'
require_relative 'spec_validator/rules/exclusive_maximum'
require_relative 'spec_validator/rules/content_media_type_in_30'
require_relative 'spec_validator/rules/prefix_items_in_30'
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
          Rules::ContentMediaTypeIn30,
          Rules::PrefixItemsIn30,
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
        ]
      end
  end
end

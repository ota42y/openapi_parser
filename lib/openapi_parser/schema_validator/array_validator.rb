class OpenAPIParser::SchemaValidator
  class ArrayValidator < Base
    include ::OpenAPIParser::SchemaValidator::Enumable

    # @param [Array] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema, **_keyword_args)
      return OpenAPIParser::ValidateError.build_error_result(value, schema) unless value.kind_of?(Array)

      value, err = validate_max_min_items(value, schema)
      return [nil, err] if err

      value, err = validate_unique_items(value, schema)
      return [nil, err] if err

      value, err = validate_contains(value, schema)
      return [nil, err] if err

      # 3.1: prefixItems positionally validates the leading N elements.
      # Elements past the prefix fall back to schema.items, matching how
      # JSON Schema 2020-12 layers the two keywords.
      prefix_schemas = schema.prefix_items || []
      items_schema = schema.items
      coerced_values = value.each_with_index.map do |v, idx|
        sub_schema = prefix_schemas[idx] || items_schema
        coerced, err = validatable.validate_schema(v, sub_schema)
        return [nil, err] if err

        coerced
      end

      value.each_index { |idx| value[idx] = coerced_values[idx] } if @coerce_value

      check_enum_include(value, schema)
    end

    def validate_max_min_items(value, schema)
      return [nil, OpenAPIParser::MoreThanMaxItems.new(value, schema.object_reference)] if schema.maxItems && value.length > schema.maxItems
      return [nil, OpenAPIParser::LessThanMinItems.new(value, schema.object_reference)] if schema.minItems && value.length < schema.minItems

      [value, nil]
    end

    def validate_unique_items(value, schema)
      return [nil, OpenAPIParser::NotUniqueItems.new(value, schema.object_reference)] if schema.uniqueItems && value.length != value.uniq.length

      [value, nil]
    end

    # 3.1: `contains` counts the items valid against its schema.
    # The count must be at least `minContains` (1 by default) and at most `maxContains`.
    # It only checks the items, so the values it coerces are dropped.
    def validate_contains(value, schema)
      contains_schema = schema.contains
      return [value, nil] unless contains_schema.is_a?(OpenAPIParser::Schemas::Schema)

      count = value.count do |item|
        _, err = validatable.validate_schema(item, contains_schema)
        err.nil?
      end

      min = non_negative_integer?(schema.minContains) ? schema.minContains : 1
      max = schema.maxContains
      return [nil, OpenAPIParser::MoreThanMaxContains.new(value, schema.object_reference)] if non_negative_integer?(max) && count > max
      return [nil, OpenAPIParser::LessThanMinContains.new(value, schema.object_reference)] if count < min

      [value, nil]
    end

    # JSON Schema counts a number with a zero fractional part, like 2.0, as an integer.
    def non_negative_integer?(number)
      number.is_a?(Numeric) && number.finite? && number >= 0 && number == number.to_i
    end
  end
end

class OpenAPIParser::SchemaValidator
  module MinimumMaximum
    # check minimum and maximum value by schema
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def check_minimum_maximum(value, schema)
      has_min_or_max = schema.minimum || schema.maximum
      has_numeric_exclusive_min = schema.exclusiveMinimum.is_a?(Numeric)
      return [value, nil] unless has_min_or_max || has_numeric_exclusive_min

      validate(value, schema)
      [value, nil]
    rescue OpenAPIParser::OpenAPIError => e
      return [nil, e]
    end

    private

      def validate(value, schema)
        reference = schema.object_reference

        # 3.1: exclusiveMinimum is a standalone numeric bound.
        if schema.exclusiveMinimum.is_a?(Numeric) && value <= schema.exclusiveMinimum
          raise OpenAPIParser::LessThanExclusiveMinimum.new(value, reference)
        end

        if schema.minimum
          # 3.0: exclusiveMinimum is a Boolean modifier on `minimum`.
          if schema.exclusiveMinimum == true && value <= schema.minimum
            raise OpenAPIParser::LessThanExclusiveMinimum.new(value, reference)
          elsif value < schema.minimum
            raise OpenAPIParser::LessThanMinimum.new(value, reference)
          end
        end

        if schema.maximum
          if schema.exclusiveMaximum && value >= schema.maximum
            raise OpenAPIParser::MoreThanExclusiveMaximum.new(value, reference)
          elsif value > schema.maximum
            raise OpenAPIParser::MoreThanMaximum.new(value, reference)
          end
        end
      end
  end
end

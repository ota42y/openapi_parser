class OpenAPIParser::Schema31Validator
  module MinimumMaximum
    # check minimum and maximum value by schema
    # @param [Object] value
    # @param [OpenAPIParser::Schemas31Schema] schema
    def check_minimum_maximum(value, schema)
      include_min_max = schema.minimum || schema.maximum
      return [value, nil] unless include_min_max

      validate(value, schema)
      [value, nil]
    rescue OpenAPIParser::OpenAPIError => e
      return [nil, e]
    end

    private

      def validate(value, schema)
        reference = schema.object_reference

        if schema.minimum
          if schema.exclusiveMinimum.present? && value <= schema.exclusiveMinimum
            raise OpenAPIParser::LessThanExclusiveMinimum.new(value, reference)
          elsif value < schema.minimum
            raise OpenAPIParser::LessThanMinimum.new(value, reference)
          end
        end

        if schema.maximum
          if schema.exclusiveMaximum.present? && value >= schema.exclusiveMinimum
            raise OpenAPIParser::MoreThanExclusiveMaximum.new(value, reference)
          elsif value > schema.maximum
            raise OpenAPIParser::MoreThanMaximum.new(value, reference)
          end
        end
      end
  end
end

class OpenAPIParser::SchemaValidator
  module PropertiesNumber
    # check minProperties and manProperties value by schema
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def check_properties_number(value, schema)
      include_properties_num = schema.minProperties || schema.maxProperties
      return [value, nil] unless include_properties_num

      validate(value, schema)
      [value, nil]
    rescue OpenAPIParser::OpenAPIError => e
      return [nil, e]
    end

    private

      def validate(value, schema)
        reference = schema.object_reference

        if schema.minProperties && (value.size < schema.minProperties)
          raise OpenAPIParser::LessThanMinProperties.new(value, reference)
        end

        if schema.maxProperties && (value.size > schema.maxProperties)
          raise OpenAPIParser::MoreThanMaxProperties.new(value, reference)
        end
      end
  end
end

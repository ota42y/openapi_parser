class OpenAPIParser::SchemaValidator
  class ObjectValidator < Base

    def initialize(validator, coerce_value, handle_readOnly)
      super(validator, coerce_value)
      @handle_readOnly = handle_readOnly
    end
    # @param [Hash] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    # @param [Boolean] parent_all_of true if component is nested under allOf
    # @param [String, nil] discriminator_property_name discriminator.property_name to ignore checking additional_properties
    def coerce_and_validate(value, schema, parent_all_of: false, parent_discriminator_schemas: [], discriminator_property_name: nil)
      return OpenAPIParser::ValidateError.build_error_result(value, schema) unless value.kind_of?(Hash)

      properties = schema.properties || {}

      required_set = schema.required ? schema.required.to_set : Set.new

      if @handle_readOnly == :ignore
        schema.properties.each do |name, property_value|
          next unless property_value.read_only
          required_set.delete(name)
          value.delete(name)
        end
      end

      remaining_keys = value.keys

      if schema.discriminator && !parent_discriminator_schemas.include?(schema)
        return validate_discriminator_schema(
          schema.discriminator,
          value,
          parent_discriminator_schemas: parent_discriminator_schemas + [schema]
        )
      else
        remaining_keys.delete('discriminator')
      end

      coerced_values = value.map do |name, v|
        s = properties[name]
        coerced, err = if s
                         remaining_keys.delete(name)
                         validatable.validate_schema(v, s)
                       elsif schema.additional_properties != true && schema.additional_properties != false
                         validatable.validate_schema(v, schema.additional_properties)
                       else
                         [v, nil]
                       end

        return [nil, err] if err

        required_set.delete(name)
        [name, coerced]
      end

      remaining_keys.delete(discriminator_property_name) if discriminator_property_name

      if !remaining_keys.empty? && !schema.additional_properties
        return [nil, OpenAPIParser::NotExistPropertyDefinition.new(remaining_keys, schema.object_reference)]
      end
      return [nil, OpenAPIParser::NotExistRequiredKey.new(required_set.to_a, schema.object_reference)] unless required_set.empty?

      value.merge!(coerced_values.to_h) if @coerce_value

      [value, nil]
    end
  end
end

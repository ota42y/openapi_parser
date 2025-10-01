class OpenAPIParser::SchemaValidator
  class ObjectValidator < Base
    include ::OpenAPIParser::SchemaValidator::PropertiesNumber

    # @param [Hash] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    # @param [Boolean] parent_all_of true if component is nested under allOf
    # @param [String, nil] discriminator_property_name discriminator.property_name to ignore checking additional_properties
    def coerce_and_validate(value, schema, parent_all_of: false, parent_discriminator_schemas: [], discriminator_property_name: nil)
      return OpenAPIParser::ValidateError.build_error_result(value, schema) unless value.kind_of?(Hash)

      properties = schema.properties || {}
      additional_properties = schema.additional_properties

      required_set = schema.required ? schema.required.to_set : Set.new
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
                       # TODO: better handling for parent_all_of with additional_properties
                       elsif !parent_all_of && additional_properties.is_a?(OpenAPIParser::Schemas::Schema)
                         remaining_keys.delete(name)
                         validatable.validate_schema(v, additional_properties)
                       else
                         [v, nil]
                       end

        return [nil, err] if err

        required_set.delete(name)
        [name, coerced]
      end

      remaining_keys.delete(discriminator_property_name) if discriminator_property_name

      if !remaining_keys.empty? && !parent_all_of && !additional_properties
        # If object is nested in all of, the validation is already done in allOf validator. Or if
        # additionalProperties are defined, we will validate using that
        return [nil, OpenAPIParser::NotExistPropertyDefinition.new(remaining_keys, schema.object_reference)]
      end
      return [nil, OpenAPIParser::NotExistRequiredKey.new(required_set.to_a, schema.object_reference)] unless required_set.empty?

      value.merge!(coerced_values.to_h) if @coerce_value

      check_properties_number(value, schema)
    end
  end
end

# validate AllOf schema
class OpenAPIParser::SchemaValidator
  class AllOfValidator < Base
    # coerce and validate value
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def coerce_and_validate(value, schema, **keyword_args)
      if value.nil? && schema.nullable
        return [value, nil]
      end

      # if any schema return error, it's not a valid all_of
      # Members with `type` go first, so that the other members see the coerced value.
      steps = schema.all_of.partition(&:type).flatten.map do |s|
        lambda do |input|
          # We need to store the reference to all of, so we can perform strict check on allowed properties
          validatable.validate_schema(
            input,
            s,
            :parent_all_of => true,
            parent_discriminator_schemas: keyword_args[:parent_discriminator_schemas] || []
          )
        end
      end
      coerced, err = validatable.validate_in_order(value, steps)
      return [nil, err] if err

      remaining_keys               = value.kind_of?(Hash) ? value.keys : []
      nested_additional_properties = false
      schema.all_of.each do |s|
        if s.type == "object"
          remaining_keys               -= (s.properties || {}).keys
          patterns                     = (s.pattern_properties || {}).keys
          remaining_keys               = remaining_keys.reject { |key| patterns.any? { |pattern| key =~ /#{pattern}/ } }
          nested_additional_properties = true if s.additional_properties
        else
          # If this is not allOf having array of objects inside, but e.g. having another anyOf/oneOf nested
          remaining_keys.clear
        end
      end

      # If there are nested additionalProperties, we allow not defined extra properties and lean on the specific
      # additionalProperties validation
      if !nested_additional_properties && !remaining_keys.empty?
        return [nil, OpenAPIParser::NotExistPropertyDefinition.new(remaining_keys, schema.object_reference)]
      end

      [coerced, nil]
    end
  end
end

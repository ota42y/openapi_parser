class OpenAPIParser::SchemaValidator
  class Base
    def initialize(validatable, coerce_value)
      @validatable = validatable
      @coerce_value = coerce_value
    end

    attr_reader :validatable

    # need override
    def coerce_and_validate(_value, _schema, **_keyword_args)
      raise 'need implement'
    end

    def validate_discriminator_schema(discriminator, value, candidate_schemas: nil, parent_discriminator_schemas: [])
      property_name = discriminator.property_name
      if property_name.nil? || !value.key?(property_name)
        return [nil, OpenAPIParser::NotExistDiscriminatorPropertyName.new(discriminator.property_name, value, discriminator.object_reference)]
      end
      mapping_key = value[property_name]

      mapping_target = discriminator.mapping&.[](mapping_key)
      if mapping_target
        resolved_schema = discriminator.root.find_object(mapping_target)
      else
        mapping_target = "#/components/schemas/#{mapping_key}"
        # Implicit values are component names, not reference paths.
        resolved_schema = discriminator.root.components&.schemas&.[](mapping_key.to_s)
        resolved_schema = nil if candidate_schemas && resolved_schema && !candidate_schemas.include?(resolved_schema)
      end

      unless resolved_schema
        return [nil, OpenAPIParser::NotExistDiscriminatorMappedSchema.new(mapping_target, discriminator.object_reference)]
      end
      validatable.validate_schema(
        value,
        resolved_schema,
        **{discriminator_property_name: discriminator.property_name, parent_discriminator_schemas: parent_discriminator_schemas}
      )
    end
  end
end

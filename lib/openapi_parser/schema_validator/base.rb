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

    def validate_discriminator_schema(discriminator, value, parent_discriminator_schemas: [])
      property_name = discriminator.property_name
      unless (property_name && value.key?(property_name))
        return [nil, OpenAPIParser::NotExistDiscriminatorPropertyName.new(discriminator.property_name, value, discriminator.object_reference)]
      end
      mapping_key = value[property_name]

      # it's allowed to have discriminator without mapping, then we need to lookup discriminator.property_name
      # but the format is not the full path, just model name in the components
      mapping_target = discriminator.mapping&.[](mapping_key) || "#/components/schemas/#{mapping_key}"

      # Find object does O(n) search at worst, then caches the result, so this is ok for repeated search
      resolved_schema = discriminator.root.find_object(mapping_target)

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

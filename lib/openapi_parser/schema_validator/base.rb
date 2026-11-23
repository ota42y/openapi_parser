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
      mapping_target, resolved_schema = resolve_discriminator_schema(discriminator, value, candidate_schemas) do |target|
        discriminator.root.find_object(target)
      end

      unless mapping_target
        return [nil, OpenAPIParser::NotExistDiscriminatorPropertyName.new(discriminator.property_name, value, discriminator.object_reference)]
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

    private

      def discriminator_member_error(discriminator, value, errors)
        return unless discriminator && value.is_a?(Hash)

        _, member = resolve_discriminator_schema(discriminator, value, errors.keys) do |target|
          find_loaded_discriminator_target(discriminator.root, target)
        end
        errors[member] if member
      end

      def resolve_discriminator_schema(discriminator, value, candidate_schemas)
        property_name = discriminator.property_name
        if property_name && value.key?(property_name)
          mapping_key = value[property_name]
          explicit_target = discriminator.mapping&.[](mapping_key)
          return [explicit_target, yield(explicit_target)] if explicit_target

          mapping_target = "#/components/schemas/#{mapping_key}"
          resolved_schema = discriminator.root.components&.schemas&.[](mapping_key.to_s)
          if resolved_schema && (!candidate_schemas || candidate_schemas.include?(resolved_schema))
            return [mapping_target, resolved_schema]
          end
        end

        default_target = default_mapping_target(discriminator)
        return [default_target, yield(default_target)] if default_target

        [mapping_target, nil]
      end

      # Error hints can use the documents already loaded for the member schemas.
      def find_loaded_discriminator_target(root, target)
        return unless target.is_a?(String)
        return root.find_object(target) if target.start_with?('#')

        reference, _, fragment = target.partition('#')
        root.load_another_schema(URI(reference), cached_only: true)&.find_object("##{fragment}")
      rescue URI::Error
        nil
      end

      # defaultMapping holds a schema name or a URI reference in OpenAPI 3.2.
      def default_mapping_target(discriminator)
        return nil unless discriminator.root.use_3_2_features?

        target = discriminator.default_mapping
        return nil unless target.is_a?(String)

        target.start_with?('#') || target.include?('/') ? target : "#/components/schemas/#{target}"
      end

      def legacy_nullable?(schema)
        schema.nullable && !schema.root.use_3_1_features?
      end
  end
end

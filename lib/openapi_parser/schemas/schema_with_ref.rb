module OpenAPIParser::Schemas
  # A Schema Object with `$ref` and other keywords next to it (OpenAPI 3.1).
  #
  # The referenced schema is shared, so the keywords cannot be merged into it.
  # The `$ref` is the base of this schema, so readers see the referenced schema,
  # as they do with a plain `$ref`. The validator checks both schemas.
  class SchemaWithRef < Schema
    # @return [Schema, Reference] Reference only when it cannot be resolved
    attr_reader :ref_target

    # @return [Schema] the keywords next to `$ref`
    attr_reader :ref_siblings

    (Schema.public_instance_methods(false) - [:load_data]).each do |name|
      define_method(name) do
        ref_target.public_send(name) if ref_target.respond_to?(name)
      end
    end

    def load_data
      siblings = raw_schema.reject { |key, _| key == '$ref' }
      @raw_schema = raw_schema.slice('$ref')
      @ref_target = Reference.new("#{object_reference}/$ref", self, root, raw_schema)
      @ref_siblings = Schema.new(object_reference, self, root, siblings)
      @_openapi_all_child_objects = { @ref_target.object_reference => @ref_target, "#{object_reference}/siblings" => @ref_siblings }
      nil
    end

    def expand_reference(root, validate_references)
      new_object = expand_object(root, @ref_target, validate_references)
      if new_object
        _update_child_object(@ref_target, new_object)
        @ref_target = new_object
      end
      @ref_siblings.expand_reference(root, validate_references)
      nil
    end
  end
end

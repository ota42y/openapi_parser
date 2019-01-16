# data type values loader
class OpenAPIParser::SchemaLoader::ValuesLoader < OpenAPIParser::SchemaLoader::Base
  # @param [OpenAPIParser::Schemas::Base] target_object
  # @param [Hash] raw_schema
  # @return [Array<OpenAPIParser::Schemas::Base>, nil, Array<OpenAPIParser::InvalidDefinitionError>]
  def load_data(target_object, raw_schema)
    variable_set(target_object, variable_name, raw_schema[schema_key.to_s])
    nil # this loader not return schema object
  end

  def definition_validate(parents, target_object)
    data = target_object.send(variable_name)

    ref = build_object_reference_from_base(target_object.object_reference, schema_key)
    [valid_definition?(target_object, ref, schema_key, data, parents, @data_types)].compact
  end
end

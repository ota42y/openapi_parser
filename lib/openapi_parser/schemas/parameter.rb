# TODO: support examples

module OpenAPIParser::Schemas
  class Parameter < Base
    openapi_attr_values :name, :in, :description, :required, :deprecated, :style, :explode, :example

    openapi_attr_value :allow_empty_value, schema_key: :allowEmptyValue
    openapi_attr_value :allow_reserved, schema_key: :allowReserved

    # @!attribute [r] schema
    #   @return [Schema, Reference, nil]
    openapi_attr_object :schema, Schema, reference: true

    # @return [Object] coerced or original params
    # @param [OpenAPIParser::SchemaValidator::Options] options
    def validate_params(params, options)
      ::OpenAPIParser::SchemaValidator.validate(deserialize(params), schema, options)
    end

    # Parameters can be serialized in several different ways
    # See [documentation](https://swagger.io/docs/specification/serialization/) for details
    # @return [Object] deserialized version of parameters
    def deserialize(params)
      # binding.pry
      return params unless params.kind_of?(String)
      if explode == false
        delimiter = case style
        when 'spaceDelimited'
          ' '
        when 'pipeDelimited'
          '|'
        else
          ','
        end
        params = params.split(delimiter)
      end
      params
    end
  end
end

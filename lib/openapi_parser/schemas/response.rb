# TODO: links

module OpenAPIParser::Schemas
  class Response < Base
    include OpenAPIParser::MediaTypeSelectable

    openapi_attr_values :description

    # @!attribute [r] content
    #   @return [Hash{String => MediaType}, nil] content_type to MediaType hash
    openapi_attr_hash_object :content, MediaType, reference: false

    # @!attribute [r] headers
    #   @return [Hash{String => Header}, nil] header string to Header
    openapi_attr_hash_object :headers, Header, reference: true

    # @param [OpenAPIParser::RequestOperation::ValidatableResponseBody] response_body
    # @param [OpenAPIParser::SchemaValidator::ResponseValidateOptions] response_validate_options
    def validate(response_body, response_validate_options)
      validate_header(response_body.headers) if response_validate_options.validate_header

      media_type = select_media_type(response_body.content_type)
      unless media_type
        if response_validate_options.strict && response_body_not_blank(response_body)
          raise ::OpenAPIParser::NotExistContentTypeDefinition, object_reference
        end

        return true
      end

      options = ::OpenAPIParser::SchemaValidator::Options.new(**response_validate_options.validator_options)
      media_type.validate_parameter(response_body.response_data, options)
    end

    # select media type by content_type (consider wild card definition)
    # @param [String] content_type
    # @return [OpenAPIParser::Schemas::MediaType, nil]
    def select_media_type(content_type)
      select_media_type_from_content(content_type, content)
    end

    private

      # @param [OpenAPIParser::RequestOperation::ValidatableResponseBody]
      def response_body_not_blank(response_body)
        !(response_body.response_data.nil? || response_body.response_data.empty?)
      end

      # @param [Hash] response_headers
      def validate_header(response_headers)
        return unless headers

        headers.each do |name, schema|
          next unless response_headers.key?(name)

          value = response_headers[name]
          schema.validate(value)
        end
      end
  end
end

module OpenAPIParser::MediaTypeSelectable
  # `content` accepts $refs only where 3.2 runtime behavior applies; before
  # 3.2 a `$ref` there is parsed as a MediaType with no schema, as it always was
  CONTENT_REFERENCE = ->(target) { target.root.use_3_2_features? }

  # A `content` $ref left unresolved (strict_reference_validation off) falls
  # back to a schemaless MediaType instead of staying a Reference
  def expand_reference(root, validate_references)
    super

    content&.each do |key, media_type|
      next unless media_type.kind_of?(OpenAPIParser::Schemas::Reference)

      fallback = OpenAPIParser::Schemas::MediaType.new(media_type.object_reference, self, root, media_type.raw_schema)
      _update_child_object(media_type, fallback)
      content[key] = fallback
    end
  end

  private

    # select media type by content_type (consider wild card definition)
    # @param [String] content_type
    # @param [Hash{String => OpenAPIParser::Schemas::MediaType}] content
    # @return [OpenAPIParser::Schemas::MediaType, nil]
    def select_media_type_from_content(content_type, content)
      return nil unless content_type
      return nil unless content

      if (media_type = content[content_type])
        return media_type
      end

      # application/json => [application, json]
      splited = content_type.split('/')

      if (media_type = content["#{splited.first}/*"])
        return media_type
      end

      if (media_type = content['*/*'])
        return media_type
      end

      nil
    end
end

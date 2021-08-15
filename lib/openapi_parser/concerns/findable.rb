require 'cgi'
require 'uri'

module OpenAPIParser::Findable
  # @param [String] reference
  # @return [OpenAPIParser::Findable]
  def find_object(reference)
    return self if object_reference == reference
    remote_reference = !reference.start_with?('#')
    return find_remote_object(reference) if remote_reference
    return nil unless reference.start_with?(object_reference)

    unescaped_reference = CGI.unescape(reference)

    @find_object_cache = {} unless defined? @find_object_cache
    if (obj = @find_object_cache[unescaped_reference])
      return obj
    end

    if (child = _openapi_all_child_objects[unescaped_reference])
      @find_object_cache[unescaped_reference] = child
      return child
    end

    _openapi_all_child_objects.values.each do |c|
      if (obj = c.find_object(unescaped_reference))
        @find_object_cache[unescaped_reference] = obj
        return obj
      end
    end

    nil
  end

  def purge_object_cache
    @purged = false unless defined? @purged

    return if @purged

    @find_object_cache = {}
    @purged = true

    _openapi_all_child_objects.values.each(&:purge_object_cache)
  end

  private

    def find_remote_object(reference)
      uri, fragment = reference.split("#", 2)
      reference_uri = URI(uri)
      reference_uri.fragment = nil
      root.load_another_schema(reference_uri)&.find_object("##{fragment}")
    end
end

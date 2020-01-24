class OpenAPIParser::ParameterValidator
  class << self
    # @param [Hash{String => Parameter}] parameters_hash
    # @param [Hash] params
    # @param [String] object_reference
    # @param [OpenAPIParser::SchemaValidator::Options] options
    # @param [Boolean] is_header is header or not (ignore params key case)
    def validate_parameter(parameters_hash, params, object_reference, options, is_header = false)
      return validate_header_parameter(parameters_hash, params, object_reference, options) if is_header

      no_exist_required_key = []

      parameters_hash.each do |k, v|
        path = k.scan(/\w+/m)
        last_key = path.pop
        parent_params = path.empty? ? params : params.dig(*path)

        if parent_params && parent_params.include?(last_key)
          coerced = v.validate_params(parent_params[last_key], options)
          if options.coerce_value
            parent_params[last_key] = coerced

            until path.empty?
              last_key = path.pop
              prev_params = parent_params
              parent_params = (path.empty? ? params : params.dig(*path))
              parent_params[last_key] = prev_params
            end

            params = parent_params
          end
        elsif v.required
          no_exist_required_key << k
        end
      end

      raise OpenAPIParser::NotExistRequiredKey.new(no_exist_required_key, object_reference) unless no_exist_required_key.empty?

      params
    end

    private

    def validate_header_parameter(parameters_hash, params, object_reference, options)
      no_exist_required_key = []

      params_key_converted = params.keys.map { |k| [k.downcase, k] }.to_h
      parameters_hash.each do |k, v|
        key = params_key_converted[k.downcase]
        if params.include?(key)
          coerced = v.validate_params(params[key], options)
          params[key] = coerced if options.coerce_value
        elsif v.required
          no_exist_required_key << k
        end
      end

      raise OpenAPIParser::NotExistRequiredKey.new(no_exist_required_key, object_reference) unless no_exist_required_key.empty?

      params
    end
  end
end

class OpenAPIParser::ParameterValidator
  class << self
    # @param [Hash{String => Parameter}] parameters_hash
    # @param [Hash] params
    # @param [String] object_reference
    # @param [OpenAPIParser::SchemaValidator::Options] options
    # @param [Boolean] is_header is header or not (ignore params key case)
    def validate_parameter(parameters_hash, params, object_reference, options, is_header = false)
      no_exist_required_key = []
      error_collection = OpenAPIParser::ErrorCollection.new if options.collect_errors

      params_key_converted = params.keys.map { |k| [convert_key(k, is_header), k] }.to_h
      parameters_hash.each do |k, v|
        key = params_key_converted[convert_key(k, is_header)]
        if params.include?(key)
          begin
            coerced = v.validate_params(params[key], options)
            params[key] = coerced if options.coerce_value
          rescue OpenAPIParser::ErrorCollection => err
            error_collection.merge(err, prefix: key) if options.collect_errors
          end
        elsif v.required
          no_exist_required_key << k
        end
      end

      if options.collect_errors
        no_exist_required_key.each do |k|
          error_collection.add(nil, nil, OpenAPIParser::NotExistRequiredKey.new([k], object_reference), suffix: k)
        end
      else
        raise OpenAPIParser::NotExistRequiredKey.new(no_exist_required_key, object_reference) unless no_exist_required_key.empty?
      end
      raise error_collection if error_collection&.any?

      params
    end

    private

    def convert_key(k, is_header)
      is_header ? k&.downcase : k
    end
  end
end

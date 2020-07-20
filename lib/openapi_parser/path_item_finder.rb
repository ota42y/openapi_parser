class OpenAPIParser::PathItemFinder
  # @param [OpenAPIParser::Schemas::Paths] paths
  def initialize(paths)
    @paths = paths
  end

  # find operation object and if not exist return nil
  # @param [String, Symbol] http_method like (get, post .... allow symbol)
  # @param [String] request_path
  # @return [Result, nil]
  def operation_object(http_method, request_path)
    if (path_item_object = @paths.path[request_path])
      if (op = path_item_object.operation(http_method))
        return Result.new(path_item_object, op, request_path, {}) # find no path_params path
      end
    end

    # check with path_params
    parse_request_path(http_method, request_path)
  end

  class Result
    attr_reader :path_item_object, :operation_object, :original_path, :path_params
    # @!attribute [r] path_item_object
    #   @return [OpenAPIParser::Schemas::PathItem]
    # @!attribute [r] operation_object
    #   @return [OpenAPIParser::Schemas::Operation]
    # @!attribute [r] path_params
    #   @return [Hash{String => String}]
    # @!attribute [r] original_path
    #   @return [String]

    def initialize(path_item_object, operation_object, original_path, path_params)
      @path_item_object = path_item_object
      @operation_object = operation_object
      @original_path = original_path
      @path_params = path_params
    end
  end

  def parse_path_parameters(schema_path, request_path)
    parameters = path_parameters(schema_path)
    return nil if parameters.empty?

    params = {}
    unparsed_req = request_path.dup
    unparsed_schema = schema_path.dup

    # Iterate through each of the parameters and ensure that we can parse it.
    # If at any time the schema stops matching, abort and return `nil`.
    # The parameters must be in the same order as their appear in the schema_path.
    parameters.each do |parameter|
      start_pos = unparsed_schema.index(parameter)

      # Strip off any "header" (non-parameter value in path) in front of the param,
      # aborting if the "header" is not found in the request path
      if start_pos > 0
        header = unparsed_schema[0..(start_pos - 1)]
        return nil if unparsed_req.index(header) != 0

        unparsed_schema = unparsed_schema[start_pos..unparsed_schema.length]
        unparsed_req = unparsed_req[start_pos..unparsed_req.length]
      end

      # Remove the parameter from the schema path name and find out what is next (non-param character or EOS)
      unparsed_schema = unparsed_schema[parameter.length..unparsed_schema.length]
      if unparsed_schema.length == 0
        value = unparsed_req
        unparsed_req = ''
      else
        value_end_pos = unparsed_req.index(unparsed_schema[0])
        return nil if value_end_pos == -1

        # Capture the value and slice the string to remove it for the next iteration
        value = unparsed_req[0..(value_end_pos - 1)]
        unparsed_req = unparsed_req[value_end_pos..unparsed_req.length]
      end

      # Remove the curly braces from the parameter name before returning
      params[param_name(parameter)] = value
    end

    params
  end

  private
    def path_parameters(schema_path)
      # OAS3 follows a RFC6570 subset for URL templates
      # https://swagger.io/docs/specification/serialization/#uri-templates
      # A URL template param can be preceded optionally by a "." or ";", and can be succeeded optionally by a "*";
      # this regex returns a match of the full parameter name with all of these modifiers. Ex: {;id*}
      parameters = schema_path.scan(/(\{[\.;]*[^\{\*\}]+\**\})/)
      # The `String#scan` method returns an array of arrays; we want an array of strings
      parameters.collect { |param| param[0] }
    end

    # check if there is a identical path in the schema (without any param)
    def matches_directly?(request_path, http_method)
      @paths.path[request_path]&.operation(http_method)
    end

    # used to filter paths with different depth or without given http method
    def different_depth_or_method?(splitted_schema_path, splitted_request_path, path_item, http_method)
      splitted_schema_path.size != splitted_request_path.size || !path_item.operation(http_method)
    end

    # check if the path item is a template
    # EXAMPLE: path_template?('{id}') => true
    def path_template?(schema_path_item)
      schema_path_item.start_with?('{') && schema_path_item.end_with?('}')
    end

    # get the parameter name from the schema path item
    # EXAMPLE: param_name('{id}') => 'id'
    def param_name(schema_path_item)
      schema_path_item[1..(schema_path_item.length - 2)]
    end

    # extract params by comparing the request path and the path from schema
    # EXAMPLE:
    # extract_params(['org', '1', 'user', '2', 'edit'], ['org', '{org_id}', 'user', '{user_id}'])
    # => { 'org_id' => 1, 'user_id' => 2 }
    # return nil if the schema does not match
    def extract_params(splitted_request_path, splitted_schema_path)
      splitted_request_path.zip(splitted_schema_path).reduce({}) do |result, zip_item|
        request_path_item, schema_path_item = zip_item

        params = parse_path_parameters(schema_path_item, request_path_item)
        if params
          result.merge!(params)
        else
          return if schema_path_item != request_path_item
        end

        result
      end
    end

    # find all matching paths with parameters extracted
    # EXAMPLE:
    # [
    #    ['/user/{id}/edit', { 'id' => 1 }],
    #    ['/user/{id}/{action}', { 'id' => 1, 'action' => 'edit' }],
    #  ]
    def matching_paths_with_params(request_path, http_method)
      splitted_request_path = request_path.split('/')

      @paths.path.reduce([]) do |result, item|
        path, path_item = item
        splitted_schema_path = path.split('/')

        next result if different_depth_or_method?(splitted_schema_path, splitted_request_path, path_item, http_method)
        
        extracted_params = extract_params(splitted_request_path, splitted_schema_path)
        result << [path, extracted_params] if extracted_params
        result
      end
    end

    # find mathing path and extract params
    # EXAMPLE: find_path_and_params('get', '/user/1') => ['/user/{id}', { 'id' => 1 }]
    def find_path_and_params(http_method, request_path)
      return [request_path, {}] if matches_directly?(request_path, http_method)
      
      matching = matching_paths_with_params(request_path, http_method)

      # if there are many matching paths, return the one with the smallest number of params
      # (prefer /user/{id}/action over /user/{param_1}/{param_2} )
      matching.min_by { |match| match[0].size } 
    end

    def parse_request_path(http_method, request_path)
      original_path, path_params = find_path_and_params(http_method, request_path)
      return nil unless original_path # # can't find

      path_item_object = @paths.path[original_path]
      obj = path_item_object.operation(http_method.to_s)
      return nil unless obj

      Result.new(path_item_object, obj, original_path, path_params)
    end
end

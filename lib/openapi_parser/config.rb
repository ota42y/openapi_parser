class OpenAPIParser::Config
  def initialize(config)
    # TODO: This deprecation warning can be removed after we set the default to `true`
    # in a later (major?) version update.
    unless config.key?(:strict_reference_validation)
      msg = "[DEPRECATION] strict_reference_validation config is not set. It defaults to `false` now, " +
          "but will be `true` in a future version. Please explicitly set to `false` " +
          "if you want to skip reference validation on schema load."
      warn(msg)
    end
    @config = config
  end

  def datetime_coerce_class
    @config[:datetime_coerce_class]
  end

  def coerce_value
    @config[:coerce_value]
  end

  def expand_reference
    @config.fetch(:expand_reference, true)
  end

  def strict_response_validation
    # TODO: in a major version update, change this to default to `true`.
    # https://github.com/ota42y/openapi_parser/pull/123/files#r767142217
    @config.fetch(:strict_response_validation, false)
  end

  def strict_reference_validation
    @config.fetch(:strict_reference_validation, false)
  end

  def validate_header
    @config.fetch(:validate_header, true)
  end

  # @return [OpenAPIParser::SchemaValidator::Options]
  def request_validator_options
    @request_validator_options ||= OpenAPIParser::SchemaValidator::Options.new(coerce_value: coerce_value,
                                                                               datetime_coerce_class: datetime_coerce_class,
                                                                               validate_header: validate_header)
  end

  alias_method :request_body_options, :request_validator_options
  alias_method :path_params_options, :request_validator_options

  # @return [OpenAPIParser::SchemaValidator::ResponseValidateOptions]
  def response_validate_options
    @response_validate_options ||= OpenAPIParser::SchemaValidator::ResponseValidateOptions.
                                     new(strict: strict_response_validation, validate_header: validate_header)
  end
end

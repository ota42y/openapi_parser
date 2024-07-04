class OpenAPIParser::SchemaValidator
  class Options
    # @!attribute [r] coerce_value
    #   @return [Boolean] coerce value option on/off
    # @!attribute [r] datetime_coerce_class
    #   @return [Object, nil] coerce datetime string by this Object class
    # @!attribute [r] validate_header
    #   @return [Boolean] validate header or not
    attr_reader :coerce_value, :datetime_coerce_class, :validate_header, :redact_errors

    def initialize(coerce_value: nil, datetime_coerce_class: nil, validate_header: true, redact_errors: false)
      @coerce_value = coerce_value
      @datetime_coerce_class = datetime_coerce_class
      @validate_header = validate_header
      @redact_errors = redact_errors
    end
  end

  # response body validation option
  class ResponseValidateOptions
    # @!attribute [r] strict
    #   @return [Boolean] validate by strict (when not exist definition, raise error)
    attr_reader :strict, :validate_header, :redact_errors

    def initialize(strict: false, validate_header: true, redact_errors: false)
      @strict = strict
      @validate_header = validate_header
      @redact_errors = redact_errors
    end
  end
end

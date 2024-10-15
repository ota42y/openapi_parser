class OpenAPIParser::SchemaValidator
  class Options
    # @!attribute [r] coerce_value
    #   @return [Boolean] coerce value option on/off
    # @!attribute [r] datetime_coerce_class
    #   @return [Object, nil] coerce datetime string by this Object class
    # @!attribute [r] validate_header
    #   @return [Boolean] validate header or not
    # @!attribute [r] handle_readOnly
    #   @return [Object, nil] How to use readOnly property to process requests. Either :ignore or :raise
    attr_reader :coerce_value, :datetime_coerce_class, :validate_header, :handle_readOnly

    def initialize(coerce_value: nil, datetime_coerce_class: nil, validate_header: true, handle_readOnly: nil)
      @coerce_value = coerce_value
      @datetime_coerce_class = datetime_coerce_class
      @validate_header = validate_header
      @handle_readOnly = handle_readOnly
    end
  end

  # response body validation option
  class ResponseValidateOptions
    # @!attribute [r] strict
    #   @return [Boolean] validate by strict (when not exist definition, raise error)
    attr_reader :strict, :validate_header

    def initialize(strict: false, validate_header: true)
      @strict = strict
      @validate_header = validate_header
    end
  end
end

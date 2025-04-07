class OpenAPIParser::SchemaValidator
  class Options
    # @!attribute [r] allow_empty_date_and_datetime
    #   @return [Boolean] allow empty date and datetime values option on/off
    # @!attribute [r] coerce_value
    #   @return [Boolean] coerce value option on/off
    # @!attribute [r] datetime_coerce_class
    #   @return [Object, nil] coerce datetime string by this Object class
    # @!attribute [r] validate_header
    #   @return [Boolean] validate header or not
    attr_reader :allow_empty_date_and_datetime, :coerce_value, :datetime_coerce_class, :validate_header

    def initialize(allow_empty_date_and_datetime: false, coerce_value: nil, datetime_coerce_class: nil, validate_header: true)
      @allow_empty_date_and_datetime = allow_empty_date_and_datetime
      @coerce_value = coerce_value
      @datetime_coerce_class = datetime_coerce_class
      @validate_header = validate_header
    end
  end

  # response body validation option
  class ResponseValidateOptions
    # @!attribute [r] strict
    #   @return [Boolean] validate by strict (when not exist definition, raise error)
    attr_reader :strict, :validate_header, :validator_options

    def initialize(strict: false, validate_header: true, **validator_options)
      @validator_options = validator_options
      @strict = strict
      @validate_header = validate_header
    end
  end
end

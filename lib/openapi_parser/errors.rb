module OpenAPIParser
  class OpenAPIError < StandardError
    def initialize(reference)
      @reference = reference
    end
  end

  class ValueError < OpenAPIError
    def initialize(value, reference, options:)
      super(reference)
      @options = options
      @value = value
    end

    def redacted_value
      @options.redact_errors ? '<redacted>' : @value.inspect
    end
  end

  class MissingReferenceError < OpenAPIError
    def message
      "'#{@reference}' was referenced but could not be found"
    end
  end

  class ValidateError < ValueError
    def initialize(value, type, reference, options:)
      super(value, reference, options: options)
      @type = type
    end

    def message
      "#{@reference} expected #{@type}, but received #{@value.class}: #{redacted_value}"
    end

    class << self
      # create ValidateError for SchemaValidator return data
      # @param [Object] value
      # @param [OpenAPIParser::Schemas::Base] schema
      def build_error_result(value, schema, options:)
        [nil, OpenAPIParser::ValidateError.new(value, schema.type, schema.object_reference, options: options)]
      end
    end
  end

  class NotNullError < OpenAPIError
    def message
      "#{@reference} does not allow null values"
    end
  end

  class NotExistRequiredKey < OpenAPIError
    def initialize(keys, reference)
      super(reference)
      @keys = keys
    end

    def message
      "#{@reference} missing required parameters: #{@keys.join(", ")}"
    end
  end

  class NotExistPropertyDefinition < OpenAPIError
    def initialize(keys, reference)
      super(reference)
      @keys = keys
    end

    def message
      "#{@reference} does not define properties: #{@keys.join(", ")}"
    end
  end

  class NotExistDiscriminatorMappedSchema < OpenAPIError
    def initialize(mapped_schema_reference, reference)
      super(reference)
      @mapped_schema_reference = mapped_schema_reference
    end

    def message
      "discriminator mapped schema #{@mapped_schema_reference} does not exist in #{@reference}"
    end
  end

  class NotExistDiscriminatorPropertyName < ValueError
    def initialize(key, value, reference, options:)
      super(value, reference, options: options)
      @key   = key
    end

    def message
      "discriminator propertyName #{@key} does not exist in value #{redacted_value} in #{@reference}"
    end
  end

  class NotOneOf < ValueError
    def initialize(value, reference, options:)
      super(value, reference, options: options)
    end

    def message
      "#{redacted_value} isn't one of in #{@reference}"
    end
  end

  class NotAnyOf < ValueError
    def initialize(value, reference, options:)
      super(value, reference, options: options)
    end

    def message
      "#{redacted_value} isn't any of in #{@reference}"
    end
  end

  class NotEnumInclude < ValueError
    def initialize(value, reference, options:)
      super(value, reference, options: options)
    end

    def message
      "#{redacted_value} isn't part of the enum in #{@reference}"
    end
  end

  class LessThanMinimum < ValueError
    def initialize(value, reference, options:)
      super(value, reference, options: options)
    end

    def message
      "#{@reference} #{redacted_value} is less than minimum value"
    end
  end

  class LessThanExclusiveMinimum < ValueError
    def initialize(value, reference, options:)
      super(value, reference, options: options)
    end

    def message
      "#{@reference} #{redacted_value} cannot be less than or equal to exclusive minimum value"
    end
  end

  class MoreThanMaximum < ValueError
    def initialize(value, reference, options:)
      super(value, reference, options: options)
    end

    def message
      "#{@reference} #{redacted_value} is more than maximum value"
    end
  end

  class MoreThanExclusiveMaximum < ValueError
    def initialize(value, reference, options:)
      super(value, reference, options: options)
    end

    def message
      "#{@reference} #{redacted_value} cannot be more than or equal to exclusive maximum value"
    end
  end

  class InvalidPattern < ValueError
    def initialize(value, pattern, reference, example, options:)
      super(value, reference, options: options)
      @pattern = pattern
      @example = example
    end

    def message
      "#{@reference} pattern #{@pattern} does not match value: #{redacted_value}#{@example ? ", example: #{@example}" : ""}"
    end
  end

  class InvalidEmailFormat < ValueError
    def initialize(value, reference, options:)
      super(value, reference, options: options)
    end

    def message
      "#{@reference} email address format does not match value: #{redacted_value}"
    end
  end

  class InvalidUUIDFormat < ValueError
    def initialize(value, reference, options:)
      super(value, reference, options: options)
    end

    def message
      "#{@reference} Value: #{redacted_value} is not conformant with UUID format"
    end
  end

  class InvalidDateFormat < ValueError
    def initialize(value, reference, options:)
      super(value, reference, options: options)
    end

    def message
      "#{@reference} Value: #{redacted_value} is not conformant with date format"
    end
  end

  class InvalidDateTimeFormat < ValueError
    def initialize(value, reference, options:)
      super(value, reference, options: options)
    end

    def message
      "#{@reference} Value: #{redacted_value} is not conformant with date-time format"
    end
  end

  class NotExistStatusCodeDefinition < OpenAPIError
    def message
      "#{@reference} status code definition does not exist"
    end
  end

  class NotExistContentTypeDefinition < OpenAPIError
    def message
      "#{@reference} response definition does not exist"
    end
  end

  class MoreThanMaxLength < ValueError
    def initialize(value, reference, options:)
      super(value, reference, options: options)
    end

    def message
      "#{@reference} #{redacted_value} is longer than max length"
    end
  end

  class LessThanMinLength < ValueError
    def initialize(value, reference, options:)
      super(value, reference, options: options)
    end

    def message
      "#{@reference} #{redacted_value} is shorter than min length"
    end
  end

  class MoreThanMaxItems < ValueError
    def initialize(value, reference, options:)
      super(value, reference, options: options)
    end

    def message
      "#{@reference} #{redacted_value} contains more than max items"
    end
  end

  class LessThanMinItems < ValueError
    def initialize(value, reference, options:)
      super(value, reference, options: options)
    end

    def message
      "#{@reference} #{redacted_value} contains fewer than min items"
    end
  end

  class NotUniqueItems < ValueError
    def initialize(value, reference, options:)
      super(value, reference, options: options)
    end

    def message
      "#{@reference} #{redacted_value} contains duplicate items"
    end
  end
end

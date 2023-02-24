module OpenAPIParser
  class OpenAPIError < StandardError
    def initialize(reference)
      @reference = reference
    end
  end

  class MissingReferenceError < OpenAPIError
    def message
      "'#{@reference}' was referenced but could not be found"
    end
  end

  class ValidateError < OpenAPIError
    def initialize(data, type, reference)
      super(reference)
      @data = data
      @type = type
    end

    def message
      "#{@reference} expected #{@type}, but received #{@data.class}: #{@data.inspect}"
    end

    class << self
      # create ValidateError for SchemaValidator return data
      # @param [Object] value
      # @param [OpenAPIParser::Schemas::Base] schema
      def build_error_result(value, schema)
        [nil, OpenAPIParser::ValidateError.new(value, schema.type, schema.object_reference)]
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

  class NotExistDiscriminatorPropertyName < OpenAPIError
    def initialize(key, value, reference)
      super(reference)
      @key   = key
      @value = value
    end

    def message
      "discriminator propertyName #{@key} does not exist in value #{@value.inspect} in #{@reference}"
    end
  end

  class NotOneOf < OpenAPIError
    def initialize(value, reference)
      super(reference)
      @value = value
    end

    def message
      "#{@value.inspect} isn't one of in #{@reference}"
    end
  end

  class NotAnyOf < OpenAPIError
    def initialize(value, reference)
      super(reference)
      @value = value
    end

    def message
      "#{@value.inspect} isn't any of in #{@reference}"
    end
  end

  class NotEnumInclude < OpenAPIError
    def initialize(value, reference)
      super(reference)
      @value = value
    end

    def message
      "#{@value.inspect} isn't part of the enum in #{@reference}"
    end
  end

  class LessThanMinimum < OpenAPIError
    def initialize(value, reference)
      super(reference)
      @value = value
    end

    def message
      "#{@reference} #{@value.inspect} is less than minimum value"
    end
  end

  class LessThanExclusiveMinimum < OpenAPIError
    def initialize(value, reference)
      super(reference)
      @value = value
    end

    def message
      "#{@reference} #{@value.inspect} cannot be less than or equal to exclusive minimum value"
    end
  end

  class MoreThanMaximum < OpenAPIError
    def initialize(value, reference)
      super(reference)
      @value = value
    end

    def message
      "#{@reference} #{@value.inspect} is more than maximum value"
    end
  end

  class MoreThanExclusiveMaximum < OpenAPIError
    def initialize(value, reference)
      super(reference)
      @value = value
    end

    def message
      "#{@reference} #{@value.inspect} cannot be more than or equal to exclusive maximum value"
    end
  end

  class InvalidPattern < OpenAPIError
    def initialize(value, pattern, reference, example)
      super(reference)
      @value = value
      @pattern = pattern
      @example = example
    end

    def message
      "#{@reference} pattern #{@pattern} does not match value: #{@value.inspect}#{@example ? ", example: #{@example}" : ""}"
    end
  end

  class InvalidEmailFormat < OpenAPIError
    def initialize(value, reference)
      super(reference)
      @value = value
    end

    def message
      "#{@reference} email address format does not match value: #{@value.inspect}"
    end
  end

  class InvalidUUIDFormat < OpenAPIError
    def initialize(value, reference)
      super(reference)
      @value = value
    end

    def message
      "#{@reference} Value: #{@value.inspect} is not conformant with UUID format"
    end
  end

  class InvalidDateFormat < OpenAPIError
    def initialize(value, reference)
      super(reference)
      @value = value
    end

    def message
      "#{@reference} Value: #{@value.inspect} is not conformant with date format"
    end
  end

  class InvalidDateTimeFormat < OpenAPIError
    def initialize(value, reference)
      super(reference)
      @value = value
    end

    def message
      "#{@reference} Value: #{@value.inspect} is not conformant with date-time format"
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

  class MoreThanMaxLength < OpenAPIError
    def initialize(value, reference)
      super(reference)
      @value = value
    end

    def message
      "#{@reference} #{@value.inspect} is longer than max length"
    end
  end

  class LessThanMinLength < OpenAPIError
    def initialize(value, reference)
      super(reference)
      @value = value
    end

    def message
      "#{@reference} #{@value.inspect} is shorter than min length"
    end
  end

  class MoreThanMaxItems < OpenAPIError
    def initialize(value, reference)
      super(reference)
      @value = value
    end

    def message
      "#{@reference} #{@value.inspect} contains more than max items"
    end
  end

  class LessThanMinItems < OpenAPIError
    def initialize(value, reference)
      super(reference)
      @value = value
    end

    def message
      "#{@reference} #{@value.inspect} contains fewer than min items"
    end
  end

  class ValidateSecurityError < OpenAPIError
    def message
      "access denied"
    end
  end
end

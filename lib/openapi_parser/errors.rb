module OpenAPIParser
  class OpenAPIError < StandardError
    def initialize(reference)
      @reference = reference
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
      "#{@value.inspect} isn't include enum in #{@reference}"
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

  class ErrorCollection < OpenAPIError
    include Enumerable

    attr_reader :errors

    def initialize
      @errors = Node.new
      @no_error = true
      @path = []
    end

    def any?
      !@no_error
    end

    def frame(key)
      @path << key
      if block_given?
        begin
          yield
        ensure
          pop_frame
        end
      end
    end

    def pop_frame
      @path.pop
    end

    def add(schema, validator, err, suffix: nil)
      node = @errors[[*@path, suffix].compact]
      if err
        @no_error = false
        node << err
      else
        node.passed
      end
    end

    def message
      map do |path, error|
        "#{path.join(".")}: #{error.message}"
      end.join("\n")
    end

    def each(&b)
      @errors.each(&b)
    end

    def merge(other, prefix: nil)
      @errors.merge(other.errors, prefix: prefix)
    end

    class Node
      attr_reader :children, :errors, :no_error, :passed_count

      def initialize(parent = nil)
        @parent = parent
        @passed_count = 0
        @no_error = true
        @children = {}
        @errors = []
      end

      def each(path = [], &b)
        @errors.each do |error|
          yield path, error
        end
        @children.each do |key, child|
          child.each([*path, key], &b)
        end
      end

      def [](keys)
        return self if keys.empty?
        key, *rest = keys
        child = @children[key] ||= Node.new(self)
        child[rest]
      end

      def <<(err)
        error!
        if err.is_a?(OpenAPIParser::NotOneOf)
          max_count = -1
          max_count_child = nil
          @children.each do |key, child|
            if child.passed_count > max_count
              max_count = child.passed_count
              max_count_child = child
            end
          end

          @children.clear
          if max_count_child
            merge(max_count_child)
          else
            @errors << err
          end
        else
          @errors << err
        end
      end

      def error!
        @no_error = false
        @parent&.error!
      end

      def passed
        return unless @no_error
        @parent&.passed
        @passed_count += 1
      end

      def merge(other, prefix: nil)
        @no_error ||= other. no_error
        if prefix
          node = self[prefix]
        else
          node = self
        end
        children = node.children
        errors = node.errors
        other.children.each do |key, child|
          children[key] = child
        end
        errors.concat other.errors
      end
    end
  end
end

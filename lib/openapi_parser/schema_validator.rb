require_relative 'schema_validator/options'
require_relative 'schema_validator/enumable'
require_relative 'schema_validator/minimum_maximum'
require_relative 'schema_validator/base'
require_relative 'schema_validator/string_validator'
require_relative 'schema_validator/integer_validator'
require_relative 'schema_validator/float_validator'
require_relative 'schema_validator/boolean_validator'
require_relative 'schema_validator/object_validator'
require_relative 'schema_validator/array_validator'
require_relative 'schema_validator/any_of_validator'
require_relative 'schema_validator/all_of_validator'
require_relative 'schema_validator/one_of_validator'
require_relative 'schema_validator/nil_validator'
require_relative 'schema_validator/unspecified_type_validator'

class OpenAPIParser::SchemaValidator
  # validate value by schema
  # this module for SchemaValidators::Base
  # @param [Object] value
  # @param [OpenAPIParser::Schemas::Schema] schema
  module Validatable
    def validate_schema(value, schema, **keyword_args)
      raise 'implement'
    end

    # validate integer value by schema
    # this method use from float_validator because number allow float and integer
    # @param [Object] _value
    # @param [OpenAPIParser::Schemas::Schema] _schema
    def validate_integer(_value, _schema)
      raise 'implement'
    end
  end

  include Validatable

  class << self
    # validate schema data
    # @param [Hash] value
    # @param [OpenAPIParser::Schemas:v:Schema]
    # @param [OpenAPIParser::SchemaValidator::Options] options
    # @return [Object] coerced or original params
    def validate(value, schema, options)
      new(value, schema, options).validate_data
    end
  end

  # @param [Hash] value
  # @param [OpenAPIParser::Schemas::Schema] schema
  # @param [OpenAPIParser::SchemaValidator::Options] options
  def initialize(value, schema, options)
    @value = value
    @schema = schema
    @options = options
  end

  # execute validate data
  # @return [Object] coerced or original params
  def validate_data
    coerced, err = validate_schema(@value, @schema)
    raise err if err

    coerced
  end

  # validate value eby schema
  # @param [Object] value
  # @param [OpenAPIParser::Schemas::Schema] schema
  def validate_schema(value, schema, **keyword_args)
    return [value, nil] unless schema

    if (v = validator(value, schema))
      if keyword_args.empty?
        return v.coerce_and_validate(value, schema)
      else
        return v.coerce_and_validate(value, schema, **keyword_args)
      end
    end

    # unknown return error
    OpenAPIParser::ValidateError.build_error_result(value, schema, options: @options)
  end

  # validate integer value by schema
  # this method use from float_validator because number allow float and integer
  # @param [Object] value
  # @param [OpenAPIParser::Schemas::Schema] schema
  def validate_integer(value, schema)
    integer_validator.coerce_and_validate(value, schema)
  end

  private

    # @return [OpenAPIParser::SchemaValidator::Base, nil]
    def validator(value, schema)
      return any_of_validator if schema.any_of
      return all_of_validator if schema.all_of
      return one_of_validator if schema.one_of
      return nil_validator if value.nil?

      case schema.type
      when 'string'
        string_validator
      when 'integer'
        integer_validator
      when 'boolean'
        boolean_validator
      when 'number'
        float_validator
      when 'object'
        object_validator
      when 'array'
        array_validator
      else
        unspecified_type_validator
      end
    end

    def string_validator
      @string_validator ||= OpenAPIParser::SchemaValidator::StringValidator.new(self, options: @options)
    end

    def integer_validator
      @integer_validator ||= OpenAPIParser::SchemaValidator::IntegerValidator.new(self, options: @options)
    end

    def float_validator
      @float_validator ||= OpenAPIParser::SchemaValidator::FloatValidator.new(self, options: @options)
    end

    def boolean_validator
      @boolean_validator ||= OpenAPIParser::SchemaValidator::BooleanValidator.new(self, options: @options)
    end

    def object_validator
      @object_validator ||= OpenAPIParser::SchemaValidator::ObjectValidator.new(self, options: @options)
    end

    def array_validator
      @array_validator ||= OpenAPIParser::SchemaValidator::ArrayValidator.new(self, options: @options)
    end

    def any_of_validator
      @any_of_validator ||= OpenAPIParser::SchemaValidator::AnyOfValidator.new(self, options: @options)
    end

    def all_of_validator
      @all_of_validator ||= OpenAPIParser::SchemaValidator::AllOfValidator.new(self, options: @options)
    end

    def one_of_validator
      @one_of_validator ||= OpenAPIParser::SchemaValidator::OneOfValidator.new(self, options: @options)
    end

    def nil_validator
      @nil_validator ||= OpenAPIParser::SchemaValidator::NilValidator.new(self, options: @options)
    end

    def unspecified_type_validator
      @unspecified_type_validator ||= OpenAPIParser::SchemaValidator::UnspecifiedTypeValidator.new(self, options: @options)
    end
end

class OpenAPIParser::SchemaValidator
  class StringValidator < Base
    include ::OpenAPIParser::SchemaValidator::Enumable

    def initialize(validator, allow_empty_date_and_datetime, coerce_value, datetime_coerce_class, date_coerce_class)
      super(validator, coerce_value)
      @allow_empty_date_and_datetime = allow_empty_date_and_datetime
      @datetime_coerce_class = datetime_coerce_class
      @date_coerce_class = date_coerce_class
    end

    def coerce_and_validate(value, schema, **_keyword_args)
      unless value.kind_of?(String)
        # Skip validation if the format is `binary`, even if the value is not an actual string.
        # ref: https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.3.md#data-types
        if schema.format == 'binary'
          # TODO:
          # It would be better to check whether the value is an instance of `Rack::Multipart::UploadFile`,
          # `ActionDispatch::Http::UploadedFile`, or another similar class.
          return [value, nil]
        end

        return OpenAPIParser::ValidateError.build_error_result(value, schema)
      end

      value, err = check_enum_include(value, schema)
      return [nil, err] if err

      value, err = pattern_validate(value, schema)
      return [nil, err] if err

      value, err = validate_max_min_length(value, schema)
      return [nil, err] if err

      value, err = validate_email_format(value, schema)
      return [nil, err] if err

      value, err = validate_uuid_format(value, schema)
      return [nil, err] if err

      value, err = validate_date_format(value, schema)
      return [nil, err] if err

      value, err = validate_datetime_format(value, schema)
      return [nil, err] if err

      [value, nil]
    end

    private

      # @param [OpenAPIParser::Schemas::Schema] schema
      def pattern_validate(value, schema)
        # pattern support string only so put this
        return [value, nil] unless schema.pattern
        return [value, nil] if value =~ /#{schema.pattern}/

        [nil, OpenAPIParser::InvalidPattern.new(value, schema.pattern, schema.object_reference, schema.example)]
      end

      def validate_max_min_length(value, schema)
        return [nil, OpenAPIParser::MoreThanMaxLength.new(value, schema.object_reference)] if schema.maxLength && value.size > schema.maxLength
        return [nil, OpenAPIParser::LessThanMinLength.new(value, schema.object_reference)] if schema.minLength && value.size < schema.minLength

        [value, nil]
      end

      def validate_email_format(value, schema)
        return [value, nil] unless schema.format == 'email'

        return [value, nil] if value.match?(URI::MailTo::EMAIL_REGEXP)

        return [nil, OpenAPIParser::InvalidEmailFormat.new(value, schema.object_reference)]
      end

      def validate_uuid_format(value, schema)
        return [value, nil] unless schema.format == 'uuid'

        return [value, nil] if value.match(/^[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}$/)

        return [nil, OpenAPIParser::InvalidUUIDFormat.new(value, schema.object_reference)]
      end

      def validate_date_format(value, schema)
        if @allow_empty_date_and_datetime && value.to_s.empty?
          return [value, nil] if schema.format == 'date'
        end

        return [value, nil] unless schema.format == 'date'

        return [nil, OpenAPIParser::InvalidDateFormat.new(value, schema.object_reference)] unless value =~ /^\d{4}-\d{2}-\d{2}$/

        begin
          if @date_coerce_class.nil?
            # validate only
            Date.iso8601(value)
            [value, nil]
          else
            # validate and coerce
            [@date_coerce_class.iso8601(value), nil]
          end
        rescue ArgumentError
          # when rfc3339(value) failed
          [nil, OpenAPIParser::InvalidDateFormat.new(value, schema.object_reference)]
        end
      end

      def validate_datetime_format(value, schema)
        if @allow_empty_date_and_datetime && value.to_s.empty?
          return [value, nil] if schema.format == 'date-time'
        end

        return [value, nil] unless schema.format == 'date-time'

        begin
          if @datetime_coerce_class.nil?
            # validate only
            DateTime.rfc3339(value)
            [value, nil]
          else
            # validate and coerce
            if @datetime_coerce_class == Time
              [DateTime.rfc3339(value).to_time, nil]
            else
              [@datetime_coerce_class.rfc3339(value), nil]
            end
          end
        rescue ArgumentError
          # when rfc3339(value) failed
          [nil, OpenAPIParser::InvalidDateTimeFormat.new(value, schema.object_reference)]
        end
      end
  end
end

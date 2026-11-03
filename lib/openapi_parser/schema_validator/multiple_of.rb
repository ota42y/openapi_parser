class OpenAPIParser::SchemaValidator
  module MultipleOf
    # check multipleOf by schema
    # @param [Numeric] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    def check_multiple_of(value, schema)
      multiple_of = schema.multipleOf
      # multipleOf MUST be a number strictly greater than 0; ignore an invalid one.
      return [value, nil] unless multiple_of.is_a?(Numeric) && multiple_of.positive?
      return [value, nil] if (exact(value) % exact(multiple_of)).zero?

      [nil, OpenAPIParser::NotMultipleOf.new(value, multiple_of, schema.object_reference)]
    end

    private

      # A Float such as 0.01 is not exact in binary, so 19.99 % 0.01 is not zero.
      # Both numbers come from decimal text in JSON or YAML, so divide them as
      # the decimals that Float#to_s gives back.
      def exact(number)
        return Rational(number.to_s) if number.is_a?(Float) && number.finite?

        number
      end
  end
end

# TODO: support servers
# TODO: support reference

module OpenAPIParser::Schemas
  class PathItem < Base
    # `query` is an OpenAPI 3.2 addition
    STANDARD_METHODS = %w[get put post delete options head patch trace query].freeze
    PRE_3_2_METHODS = (STANDARD_METHODS - %w[query]).freeze

    openapi_attr_values :summary, :description

    openapi_attr_objects :get, :put, :post, :delete, :options, :head, :patch, :trace, :query, Operation
    openapi_attr_list_object :parameters, Parameter, reference: true

    # @!attribute [r] additional_operations
    #   @return [Hash{String => Operation}, nil] operations for non-standard HTTP methods (OpenAPI 3.2+)
    openapi_attr_hash_object :additional_operations, Operation, reference: false, schema_key: :additionalOperations

    # @return [Operation, nil]
    def operation(method)
      # before 3.2: exact-case standard methods only, as it always was
      unless root.use_3_2_features?
        return PRE_3_2_METHODS.include?(method.to_s) ? public_send(method.to_s) : nil
      end

      method_name = method.to_s.downcase
      return public_send(method_name) if STANDARD_METHODS.include?(method_name)

      additional_operation(method.to_s)
    end

    def set_path_item_to_operation
      STANDARD_METHODS.each { |method| operation(method)&.set_parent_path_item(self) }
      additional_operations&.each_value { |op| op.set_parent_path_item(self) }
    end

    private

      # additionalOperations keys are method names as sent on the wire
      # (conventionally uppercase); prefer an exact match, else ignore case
      def additional_operation(name)
        operations = additional_operations
        return nil unless operations

        operations.fetch(name) { operations.find { |key, _| key.casecmp?(name) }&.last }
      end
  end
end

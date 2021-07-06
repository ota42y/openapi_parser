# TODO: support servers
# TODO: support reference

module OpenAPIParser::Schemas
  class PathItem < Base
    openapi_attr_values :summary, :description

    openapi_attr_objects :get, :put, :post, :delete, :options, :head, :patch, :trace, Operation
    openapi_attr_list_object :parameters, Parameter, reference: true

    # @return [Operation]
    def operation(method)
      public_send(method)
    rescue NoMethodError
      nil
    end

    def set_path_item_to_operation
      [:get, :put, :post, :delete, :options, :head, :patch, :trace].each{ |method| operation(method)&.set_parent_path_item(self)}
    end
  end
end

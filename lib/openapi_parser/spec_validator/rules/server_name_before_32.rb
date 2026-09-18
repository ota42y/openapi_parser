module OpenAPIParser
  class SpecValidator
    module Rules
      # 3.2 adds `name` to the Server Object. Servers are not modeled by
      # the parse layer, so this rule inspects the raw `servers` arrays on
      # the root, Path Item, and Operation objects. Servers under callbacks
      # and Link Objects are not reached.
      class ServerNameBefore32 < Rule
        def check(root)
          return [] unless version_before?('3.2')

          violations = []
          node_classes = [OpenAPIParser::Schemas::OpenAPI, OpenAPIParser::Schemas::PathItem, OpenAPIParser::Schemas::Operation]
          each_node(root, *node_classes) do |node|
            raw = node.raw_schema
            next unless raw.is_a?(Hash)

            servers = raw['servers']
            next unless servers.is_a?(Array)

            servers.each_with_index do |server, index|
              next unless server.is_a?(Hash) && server.key?('name')

              violations << violation(
                path: "#{node.object_reference}/servers/#{index}/name",
                message: '`name` on a Server Object is a 3.2 addition; earlier documents have no such field',
              )
            end
          end
          violations
        end
      end
    end
  end
end

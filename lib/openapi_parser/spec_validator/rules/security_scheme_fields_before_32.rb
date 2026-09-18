module OpenAPIParser
  class SpecValidator
    module Rules
      # 3.2 adds `deprecated` and `oauth2MetadataUrl` to the Security Scheme
      # Object and the `deviceAuthorization` OAuth flow. Security schemes are
      # not modeled by the parse layer, so this rule inspects the raw
      # `components.securitySchemes` map; schemes given as a `$ref` are not
      # followed.
      class SecuritySchemeFieldsBefore32 < Rule
        NEW_FIELDS = %w[deprecated oauth2MetadataUrl].freeze

        def check(root)
          return [] unless version_before?('3.2')

          violations = []
          each_security_scheme(root) do |name, scheme|
            base = "#/components/securitySchemes/#{escape_reference(name)}"

            NEW_FIELDS.each do |field|
              next unless scheme.key?(field)

              violations << violation(
                path: "#{base}/#{field}",
                message: "`#{field}` on a Security Scheme Object is a 3.2 addition; earlier documents have no such field",
              )
            end

            flows = scheme['flows']
            next unless flows.is_a?(Hash) && flows.key?('deviceAuthorization')

            violations << violation(
              path: "#{base}/flows/deviceAuthorization",
              message: 'the `deviceAuthorization` OAuth flow is a 3.2 addition; earlier documents have no such flow',
            )
          end
          violations
        end
      end
    end
  end
end

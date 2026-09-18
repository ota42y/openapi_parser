require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::SecuritySchemeFieldsBefore32' do
  def base_doc(openapi_version_string, schemes)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'securitySchemes' => schemes },
    }
  end

  def doc_with_new_fields(openapi_version_string)
    scheme = {
      'type' => 'oauth2',
      'deprecated' => true,
      'oauth2MetadataUrl' => 'https://auth.example.com/.well-known/oauth-authorization-server',
      'flows' => {
        'deviceAuthorization' => {
          'deviceAuthorizationUrl' => 'https://auth.example.com/device',
          'tokenUrl' => 'https://auth.example.com/token',
          'scopes' => {},
        },
      },
    }
    OpenAPIParser.parse(base_doc(openapi_version_string, { 'OAuth2' => scheme }), strict_reference_validation: false)
  end

  def doc_without_new_fields(openapi_version_string)
    scheme = {
      'type' => 'oauth2',
      'flows' => { 'clientCredentials' => { 'tokenUrl' => 'https://auth.example.com/token', 'scopes' => {} } },
    }
    OpenAPIParser.parse(base_doc(openapi_version_string, { 'OAuth2' => scheme }), strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::SecuritySchemeFieldsBefore32.new(root.openapi_version).check(root)
  end

  context 'with a 3.2 document using the new fields' do
    it 'reports no violation' do
      root = doc_with_new_fields('3.2.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.2 document without the new fields' do
    it 'reports no violation' do
      root = doc_without_new_fields('3.2.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document using the new fields' do
    it 'reports one violation per offending field' do
      root = doc_with_new_fields('3.1.0')
      violations = run_rule_for(root)
      expect(violations.map(&:path)).to match_array [
        '#/components/securitySchemes/OAuth2/deprecated',
        '#/components/securitySchemes/OAuth2/oauth2MetadataUrl',
        '#/components/securitySchemes/OAuth2/flows/deviceAuthorization',
      ]
      expect(violations.first.rule_name).to eq :security_scheme_fields_before32
    end
  end

  context 'with a 3.1 document without the new fields' do
    it 'reports no violation' do
      root = doc_without_new_fields('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using the new fields' do
    it 'reports violations' do
      root = doc_with_new_fields('3.0.0')
      expect(run_rule_for(root).size).to eq 3
    end
  end

  context 'with a 3.1 document whose scheme name contains a slash' do
    it 'escapes the name in the violation path' do
      raw = base_doc('3.1.0', { 'auth/v2' => { 'type' => 'http', 'scheme' => 'bearer', 'deprecated' => true } })
      root = OpenAPIParser.parse(raw, strict_reference_validation: false)
      expect(run_rule_for(root).map(&:path)).to eq ['#/components/securitySchemes/auth~1v2/deprecated']
    end
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)' do
      root = doc_with_new_fields('not-a-version')
      expect(run_rule_for(root)).to eq []
    end
  end
end

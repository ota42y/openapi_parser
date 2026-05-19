require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::DynamicRefIn30' do
  def base_doc(openapi_version_string, sample_schema)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => { 'Sample' => sample_schema } },
    }
  end

  def doc_with_dynamic_ref(openapi_version_string)
    raw = base_doc(openapi_version_string, { '$dynamicRef' => '#meta' })
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def doc_without_dynamic_ref(openapi_version_string)
    raw = base_doc(openapi_version_string, { 'type' => 'string' })
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::DynamicRefIn30.new(root.openapi_version).check(root)
  end

  context 'with a 3.1 document using $dynamicRef' do
    it 'reports no violation'
  end

  context 'with a 3.1 document without $dynamicRef' do
    it 'reports no violation'
  end

  context 'with a 3.0 document using $dynamicRef' do
    it 'reports one violation pointing at the offending schema'
  end

  context 'with a 3.0 document without $dynamicRef' do
    it 'reports no violation'
  end

  context 'with an :unknown version document' do
    it 'reports no violation (rule skipped)'
  end
end

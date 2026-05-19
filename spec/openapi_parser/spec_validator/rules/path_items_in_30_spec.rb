require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::PathItemsIn30' do
  def doc_with_path_items(openapi_version_string, include_path_items: true)
    components = { 'schemas' => {} }
    if include_path_items
      components['pathItems'] = {
        'sample' => { 'get' => { 'responses' => { '200' => { 'description' => 'ok' } } } },
      }
    end
    raw = {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => components,
    }
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::PathItemsIn30.new(root.openapi_version).check(root)
  end

  context 'with a 3.1 document using components.pathItems' do
    it 'reports no violation'
  end

  context 'with a 3.0 document using components.pathItems' do
    it 'reports one violation pointing at #/components/pathItems'
  end

  context 'with a 3.0 document without components.pathItems' do
    it 'reports no violation'
  end

  context 'with an :unknown version document using components.pathItems' do
    it 'reports no violation (rule skipped)'
  end
end

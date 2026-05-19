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
    it 'reports no violation' do
      root = doc_with_path_items('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using components.pathItems' do
    it 'reports one violation pointing at #/components/pathItems' do
      root = doc_with_path_items('3.0.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/components/pathItems'
      expect(violations.first.rule_name).to eq :path_items_in30
    end
  end

  context 'with a 3.0 document without components.pathItems' do
    it 'reports no violation' do
      root = doc_with_path_items('3.0.0', include_path_items: false)
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with an :unknown version document using components.pathItems' do
    it 'reports no violation (rule skipped)' do
      root = doc_with_path_items('4.0.0')
      expect(run_rule_for(root)).to eq []
    end
  end
end

require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::DefsIn30' do
  def base_doc(openapi_version_string, sample_schema)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => { 'Sample' => sample_schema } },
    }
  end

  def doc_with_defs(openapi_version_string)
    raw = base_doc(openapi_version_string, { 'type' => 'object', '$defs' => { 'Id' => { 'type' => 'integer' } } })
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def doc_without_defs(openapi_version_string)
    raw = base_doc(openapi_version_string, { 'type' => 'string' })
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::DefsIn30.new(root.openapi_version).check(root)
  end

  context 'with a 3.1 document using $defs' do
    it 'reports no violation'
  end

  context 'with a 3.1 document without $defs' do
    it 'reports no violation'
  end

  context 'with a 3.0 document using $defs' do
    it 'reports one violation pointing at the offending schema' do
      root = doc_with_defs('3.0.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/components/schemas/Sample'
      expect(violations.first.rule_name).to eq :defs_in30
    end
  end

  context 'with a 3.0 document without $defs' do
    it 'reports no violation'
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)'
  end
end

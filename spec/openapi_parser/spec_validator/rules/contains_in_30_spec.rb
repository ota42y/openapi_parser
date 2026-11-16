require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::ContainsIn30' do
  def base_doc(openapi_version_string, schemas)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => schemas },
    }
  end

  def doc_with_contains(openapi_version_string)
    raw = base_doc(openapi_version_string, { 'Sample' => { 'type' => 'array', 'contains' => { 'type' => 'integer' }, 'minContains' => 2 } })
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def doc_without_contains(openapi_version_string)
    raw = base_doc(openapi_version_string, { 'Sample' => { 'type' => 'array', 'items' => { 'type' => 'integer' } } })
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::ContainsIn30.new(root.openapi_version).check(root)
  end

  context 'with a 3.1 document using contains' do
    it 'reports no violation' do
      root = doc_with_contains('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document without contains' do
    it 'reports no violation' do
      root = doc_without_contains('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using contains' do
    it 'reports one violation pointing at the offending schema' do
      root = doc_with_contains('3.0.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/components/schemas/Sample'
      expect(violations.first.rule_name).to eq :contains_in30
    end
  end

  context 'with a 3.0 document using minContains or maxContains' do
    it 'reports one violation per schema' do
      raw = base_doc(
        '3.0.0',
        {
          'OnlyMin' => { 'type' => 'array', 'minContains' => 1 },
          'OnlyMax' => { 'type' => 'array', 'maxContains' => 1 },
        },
      )
      root = OpenAPIParser.parse(raw, strict_reference_validation: false)
      violations = run_rule_for(root)
      expect(violations.map(&:path)).to contain_exactly('#/components/schemas/OnlyMin', '#/components/schemas/OnlyMax')
    end
  end

  context 'with a 3.0 document without contains' do
    it 'reports no violation' do
      root = doc_without_contains('3.0.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)' do
      root = doc_with_contains('not-a-version')
      expect(run_rule_for(root)).to eq []
    end
  end
end

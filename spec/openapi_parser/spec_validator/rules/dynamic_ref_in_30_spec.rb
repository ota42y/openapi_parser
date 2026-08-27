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
    it 'reports no violation' do
      root = doc_with_dynamic_ref('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document without $dynamicRef' do
    it 'reports no violation' do
      root = doc_without_dynamic_ref('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using $dynamicRef' do
    it 'reports one violation pointing at the offending schema' do
      root = doc_with_dynamic_ref('3.0.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/components/schemas/Sample'
      expect(violations.first.rule_name).to eq :dynamic_ref_in30
    end
  end

  context 'with a 3.0 document without $dynamicRef' do
    it 'reports no violation' do
      root = doc_without_dynamic_ref('3.0.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with an :unknown version document' do
    it 'reports no violation (rule skipped)' do
      root = doc_with_dynamic_ref('4.0.0')
      expect(run_rule_for(root)).to eq []
    end
  end
end

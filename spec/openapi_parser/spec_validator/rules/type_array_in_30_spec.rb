require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::TypeArrayIn30' do
  def base_doc(openapi_version_string, sample_schema)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => { 'Sample' => sample_schema } },
    }
  end

  def doc_with_type_array(openapi_version_string)
    raw = base_doc(openapi_version_string, { 'type' => ['string', 'null'] })
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def doc_without_type_array(openapi_version_string)
    raw = base_doc(openapi_version_string, { 'type' => 'string' })
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::TypeArrayIn30.new(root.openapi_version).check(root)
  end

  context 'with a 3.1 document using type as Array' do
    it 'reports no violation' do
      root = doc_with_type_array('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document using type as a plain string' do
    it 'reports no violation' do
      root = doc_without_type_array('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using type as Array' do
    it 'reports one violation pointing at the offending schema' do
      root = doc_with_type_array('3.0.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/components/schemas/Sample'
      expect(violations.first.rule_name).to eq :type_array_in30
    end
  end

  context 'with a 3.0 document using type as a plain string' do
    it 'reports no violation' do
      root = doc_without_type_array('3.0.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with an :unknown version document' do
    it 'reports no violation (rule skipped)' do
      root = doc_with_type_array('4.0.0')
      expect(run_rule_for(root)).to eq []
    end
  end
end

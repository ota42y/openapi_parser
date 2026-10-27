require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::XmlWrappedDeprecation' do
  def base_doc(openapi_version_string, sample_schema)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => { 'Sample' => sample_schema } },
    }
  end

  def doc_with_wrapped(openapi_version_string)
    raw = base_doc(openapi_version_string, { 'type' => 'array', 'items' => { 'type' => 'string' }, 'xml' => { 'wrapped' => true } })
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def doc_without_wrapped(openapi_version_string)
    raw = base_doc(openapi_version_string, { 'type' => 'array', 'items' => { 'type' => 'string' }, 'xml' => { 'nodeType' => 'element' } })
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::XmlWrappedDeprecation.new(root.openapi_version).check(root)
  end

  context 'with a 3.2 document using xml wrapped' do
    it 'reports one violation pointing at the offending schema' do
      root = doc_with_wrapped('3.2.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/components/schemas/Sample'
      expect(violations.first.rule_name).to eq :xml_wrapped_deprecation
      expect(violations.first.message).to include('deprecated in 3.2')
    end
  end

  context 'with a 3.2 document using nodeType instead' do
    it 'reports no violation' do
      root = doc_without_wrapped('3.2.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.2 document using xml wrapped: false' do
    it 'reports no violation (only the true form is deprecated)' do
      raw = base_doc('3.2.0', { 'type' => 'string', 'xml' => { 'wrapped' => false } })
      root = OpenAPIParser.parse(raw, strict_reference_validation: false)
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document using xml wrapped' do
    it 'reports no violation' do
      root = doc_with_wrapped('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document without xml wrapped' do
    it 'reports no violation' do
      root = doc_without_wrapped('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using xml wrapped' do
    it 'reports no violation' do
      root = doc_with_wrapped('3.0.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)' do
      root = doc_with_wrapped('not-a-version')
      expect(run_rule_for(root)).to eq []
    end
  end
end

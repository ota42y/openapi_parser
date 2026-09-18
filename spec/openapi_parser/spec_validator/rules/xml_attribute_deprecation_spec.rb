require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::XmlAttributeDeprecation' do
  def base_doc(openapi_version_string, sample_schema)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => { 'Sample' => sample_schema } },
    }
  end

  def doc_with_attribute(openapi_version_string)
    raw = base_doc(openapi_version_string, { 'type' => 'string', 'xml' => { 'attribute' => true } })
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def doc_without_attribute(openapi_version_string)
    raw = base_doc(openapi_version_string, { 'type' => 'string', 'xml' => { 'nodeType' => 'attribute' } })
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::XmlAttributeDeprecation.new(root.openapi_version).check(root)
  end

  context 'with a 3.2 document using xml attribute' do
    it 'reports one violation pointing at the offending schema' do
      root = doc_with_attribute('3.2.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/components/schemas/Sample'
      expect(violations.first.rule_name).to eq :xml_attribute_deprecation
      expect(violations.first.message).to include('deprecated in 3.2')
    end
  end

  context 'with a 3.2 document using nodeType instead' do
    it 'reports no violation' do
      root = doc_without_attribute('3.2.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.2 document using xml attribute: false' do
    it 'reports no violation (only the true form is deprecated)' do
      raw = base_doc('3.2.0', { 'type' => 'string', 'xml' => { 'attribute' => false } })
      root = OpenAPIParser.parse(raw, strict_reference_validation: false)
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document using xml attribute' do
    it 'reports no violation' do
      root = doc_with_attribute('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document without xml attribute' do
    it 'reports no violation' do
      root = doc_without_attribute('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using xml attribute' do
    it 'reports no violation' do
      root = doc_with_attribute('3.0.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)' do
      root = doc_with_attribute('not-a-version')
      expect(run_rule_for(root)).to eq []
    end
  end
end

require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::DefaultMappingBefore32' do
  def base_doc(openapi_version_string, sample_schema)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => {
        'schemas' => {
          'Sample' => sample_schema,
          'Dog' => { 'type' => 'object' },
        },
      },
    }
  end

  def doc_with_default_mapping(openapi_version_string)
    sample = {
      'oneOf' => [{ '$ref' => '#/components/schemas/Dog' }],
      'discriminator' => { 'propertyName' => 'petType', 'defaultMapping' => 'Dog' },
    }
    OpenAPIParser.parse(base_doc(openapi_version_string, sample), strict_reference_validation: false)
  end

  def doc_without_default_mapping(openapi_version_string)
    sample = {
      'oneOf' => [{ '$ref' => '#/components/schemas/Dog' }],
      'discriminator' => { 'propertyName' => 'petType' },
    }
    OpenAPIParser.parse(base_doc(openapi_version_string, sample), strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::DefaultMappingBefore32.new(root.openapi_version).check(root)
  end

  context 'with a 3.2 document using defaultMapping' do
    it 'reports no violation' do
      root = doc_with_default_mapping('3.2.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.2 document without defaultMapping' do
    it 'reports no violation' do
      root = doc_without_default_mapping('3.2.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document using defaultMapping' do
    it 'reports one violation pointing at the offending discriminator' do
      root = doc_with_default_mapping('3.1.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/components/schemas/Sample/discriminator/defaultMapping'
      expect(violations.first.rule_name).to eq :default_mapping_before32
    end
  end

  context 'with a 3.1 document without defaultMapping' do
    it 'reports no violation' do
      root = doc_without_default_mapping('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using defaultMapping' do
    it 'reports one violation' do
      root = doc_with_default_mapping('3.0.0')
      expect(run_rule_for(root).size).to eq 1
    end
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)' do
      root = doc_with_default_mapping('not-a-version')
      expect(run_rule_for(root)).to eq []
    end
  end
end

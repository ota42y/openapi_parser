require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::BooleanSchemaIn30' do
  def base_doc(openapi_version_string, sample_schema)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => { 'Tuple' => sample_schema } },
    }
  end

  def doc_with_boolean_schema(openapi_version_string)
    raw = base_doc(
      openapi_version_string,
      {
        'type' => 'array',
        'prefixItems' => [{ 'type' => 'number' }, { 'type' => 'number' }],
        'items' => false,
      },
    )
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def doc_without_boolean_schema(openapi_version_string)
    raw = base_doc(openapi_version_string, { 'type' => 'array', 'items' => { 'type' => 'number' } })
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def doc_with_additional_properties_false(openapi_version_string)
    raw = base_doc(openapi_version_string, { 'type' => 'object', 'additionalProperties' => false })
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::BooleanSchemaIn30.new(root.openapi_version).check(root)
  end

  context 'with a 3.1 document using a boolean schema' do
    it 'reports no violation' do
      root = doc_with_boolean_schema('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document without a boolean schema' do
    it 'reports no violation' do
      root = doc_without_boolean_schema('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using a boolean schema' do
    it 'reports one violation pointing at the offending schema' do
      root = doc_with_boolean_schema('3.0.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/components/schemas/Tuple/items'
      expect(violations.first.rule_name).to eq :boolean_schema_in30
    end
  end

  context 'with a 3.0 document without a boolean schema' do
    it 'reports no violation' do
      root = doc_without_boolean_schema('3.0.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using additionalProperties: false' do
    it 'reports no violation' do
      root = doc_with_additional_properties_false('3.0.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)' do
      root = doc_with_boolean_schema('not-a-version')
      expect(run_rule_for(root)).to eq []
    end
  end
end

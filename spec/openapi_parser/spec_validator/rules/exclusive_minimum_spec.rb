require_relative '../../../spec_helper'

RSpec.describe OpenAPIParser::SpecValidator::Rules::ExclusiveMinimum do
  def schema_with_exclusive_minimum(openapi_version_string, exclusive_minimum_value, minimum_value: nil)
    schema_payload = { 'type' => 'integer', 'exclusiveMinimum' => exclusive_minimum_value }
    schema_payload['minimum'] = minimum_value if minimum_value
    raw = {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => { 'Sample' => schema_payload } },
    }
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::ExclusiveMinimum.new(root.openapi_version).check(root)
  end

  context 'with a 3.0 document using a 3.0-style boolean exclusiveMinimum' do
    it 'reports no violation' do
      root = schema_with_exclusive_minimum('3.0.0', true, minimum_value: 5)
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document using a 3.1-style numeric exclusiveMinimum' do
    it 'reports no violation' do
      root = schema_with_exclusive_minimum('3.1.0', 5)
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using a 3.1-style numeric exclusiveMinimum' do
    it 'reports one violation pointing at the offending schema' do
      root = schema_with_exclusive_minimum('3.0.0', 5)
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/components/schemas/Sample'
      expect(violations.first.rule_name).to eq :exclusive_minimum
      expect(violations.first.message).to include('numeric exclusiveMinimum')
    end
  end

  context 'with a 3.1 document using a 3.0-style boolean exclusiveMinimum' do
    it 'reports one violation pointing at the offending schema' do
      root = schema_with_exclusive_minimum('3.1.0', true, minimum_value: 5)
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/components/schemas/Sample'
      expect(violations.first.message).to include('Boolean exclusiveMinimum')
    end
  end

  context 'with an :unknown version document containing exclusiveMinimum' do
    it 'reports no violation (rule skipped)' do
      root = schema_with_exclusive_minimum('4.0.0', 5)
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a schema that has no exclusiveMinimum' do
    it 'reports no violation' do
      raw = {
        'openapi' => '3.0.0',
        'info' => { 'title' => 'test', 'version' => '1.0' },
        'paths' => {},
        'components' => { 'schemas' => { 'Sample' => { 'type' => 'integer' } } },
      }
      root = OpenAPIParser.parse(raw, strict_reference_validation: false)
      expect(run_rule_for(root)).to eq []
    end
  end
end

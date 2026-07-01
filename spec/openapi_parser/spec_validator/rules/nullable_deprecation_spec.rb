require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::NullableDeprecation' do
  def schema_with_nullable(openapi_version_string, nullable_value)
    schema_payload = { 'type' => 'string' }
    schema_payload['nullable'] = nullable_value unless nullable_value == :absent
    raw = {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => { 'Sample' => schema_payload } },
    }
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::NullableDeprecation.new(root.openapi_version).check(root)
  end

  context 'with a 3.0 document using nullable: true' do
    it 'reports no violation' do
      root = schema_with_nullable('3.0.0', true)
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using nullable: false' do
    it 'reports no violation' do
      root = schema_with_nullable('3.0.0', false)
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document using nullable: true' do
    it 'reports one violation pointing at the offending schema' do
      root = schema_with_nullable('3.1.0', true)
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/components/schemas/Sample'
      expect(violations.first.rule_name).to eq :nullable_deprecation
      expect(violations.first.message).to include('removed in 3.1')
    end
  end

  context 'with a 3.1 document using nullable: false' do
    it 'reports one violation (the field itself is removed in 3.1)' do
      root = schema_with_nullable('3.1.0', false)
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
    end
  end

  context 'with a 3.1 document that does not use nullable' do
    it 'reports no violation' do
      root = schema_with_nullable('3.1.0', :absent)
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with an :unknown version document' do
    it 'reports no violation (rule skipped)' do
      root = schema_with_nullable('4.0.0', true)
      expect(run_rule_for(root)).to eq []
    end
  end
end

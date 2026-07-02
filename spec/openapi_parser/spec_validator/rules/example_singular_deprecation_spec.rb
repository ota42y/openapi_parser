require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::ExampleSingularDeprecation' do
  def schema_with_example(openapi_version_string, schema_payload)
    raw = {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => { 'Sample' => schema_payload } },
    }
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::ExampleSingularDeprecation.new(root.openapi_version).check(root)
  end

  context 'with a 3.0 document using singular example on a Schema' do
    it 'reports no violation' do
      root = schema_with_example('3.0.0', { 'type' => 'string', 'example' => 'sample' })
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document using singular example on a Schema' do
    it 'reports one violation pointing at the offending schema' do
      root = schema_with_example('3.1.0', { 'type' => 'string', 'example' => 'sample' })
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/components/schemas/Sample'
      expect(violations.first.rule_name).to eq :example_singular_deprecation
      expect(violations.first.message).to include('deprecated in 3.1')
    end
  end

  context 'with a 3.1 document that does not use singular example' do
    it 'reports no violation' do
      root = schema_with_example('3.1.0', { 'type' => 'string' })
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document using the examples array (correct 3.1 form)' do
    it 'reports no violation' do
      root = schema_with_example('3.1.0', { 'type' => 'string', 'examples' => ['sample'] })
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with an :unknown version document' do
    it 'reports no violation (rule skipped)' do
      root = schema_with_example('4.0.0', { 'type' => 'string', 'example' => 'sample' })
      expect(run_rule_for(root)).to eq []
    end
  end
end

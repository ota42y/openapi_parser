require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::ExampleSingularDeprecation' do
  def base_doc(openapi_version_string, sample_schema)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => { 'Sample' => sample_schema } },
    }
  end

  def doc_with_example(openapi_version_string)
    raw = base_doc(openapi_version_string, { 'type' => 'string', 'example' => 'sample' })
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def doc_without_example(openapi_version_string)
    raw = base_doc(openapi_version_string, { 'type' => 'string' })
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def doc_with_examples_array(openapi_version_string)
    raw = base_doc(openapi_version_string, { 'type' => 'string', 'examples' => ['sample'] })
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::ExampleSingularDeprecation.new(root.openapi_version).check(root)
  end

  context 'with a 3.0 document using singular example on a Schema' do
    it 'reports no violation' do
      root = doc_with_example('3.0.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document without singular example' do
    it 'reports no violation' do
      root = doc_without_example('3.0.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document using singular example on a Schema' do
    it 'reports one violation pointing at the offending schema' do
      root = doc_with_example('3.1.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/components/schemas/Sample'
      expect(violations.first.rule_name).to eq :example_singular_deprecation
      expect(violations.first.message).to include('deprecated in 3.1')
    end
  end

  context 'with a 3.1 document without singular example' do
    it 'reports no violation' do
      root = doc_without_example('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document using the examples array (correct 3.1 form)' do
    it 'reports no violation' do
      root = doc_with_examples_array('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with an :unknown version document' do
    it 'reports no violation (rule skipped)' do
      root = doc_with_example('4.0.0')
      expect(run_rule_for(root)).to eq []
    end
  end
end

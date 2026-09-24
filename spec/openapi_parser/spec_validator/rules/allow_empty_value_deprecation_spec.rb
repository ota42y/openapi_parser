require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::AllowEmptyValueDeprecation' do
  def base_doc(openapi_version_string, param)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {
        '/pets' => {
          'get' => {
            'parameters' => [param],
            'responses' => { '200' => { 'description' => 'OK' } },
          },
        },
      },
    }
  end

  def doc_with(openapi_version_string)
    OpenAPIParser.parse(base_doc(openapi_version_string, { 'name' => 'q', 'in' => 'query', 'allowEmptyValue' => true, 'schema' => { 'type' => 'string' } }), strict_reference_validation: false)
  end

  def doc_without(openapi_version_string)
    OpenAPIParser.parse(base_doc(openapi_version_string, { 'name' => 'q', 'in' => 'query', 'schema' => { 'type' => 'string' } }), strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::AllowEmptyValueDeprecation.new(root.openapi_version).check(root)
  end

  context 'with a 3.2 document using allowEmptyValue' do
    it 'reports one violation pointing at the field' do
      root = doc_with('3.2.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/paths/~1pets/get/parameters/0/allowEmptyValue'
      expect(violations.first.rule_name).to eq :allow_empty_value_deprecation
      expect(violations.first.message).to include('deprecated in 3.2')
    end
  end

  context 'with a 3.2 document without allowEmptyValue' do
    it 'reports no violation' do
      expect(run_rule_for(doc_without('3.2.0'))).to eq []
    end
  end

  context 'with a 3.1 document using allowEmptyValue' do
    it 'reports no violation' do
      expect(run_rule_for(doc_with('3.1.0'))).to eq []
    end
  end

  context 'with a 3.1 document without allowEmptyValue' do
    it 'reports no violation' do
      expect(run_rule_for(doc_without('3.1.0'))).to eq []
    end
  end

  context 'with a 3.0 document using allowEmptyValue' do
    it 'reports no violation' do
      expect(run_rule_for(doc_with('3.0.0'))).to eq []
    end
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)' do
      expect(run_rule_for(doc_with('not-a-version'))).to eq []
    end
  end
end

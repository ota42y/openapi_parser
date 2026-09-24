require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::ResponseSummaryBefore32' do
  def base_doc(openapi_version_string, resp)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {
        '/pets' => {
          'get' => {
            'responses' => { '200' => resp },
          },
        },
      },
    }
  end

  def doc_with(openapi_version_string)
    OpenAPIParser.parse(base_doc(openapi_version_string, { 'summary' => 'Pets', 'description' => 'OK' }), strict_reference_validation: false)
  end

  def doc_without(openapi_version_string)
    OpenAPIParser.parse(base_doc(openapi_version_string, { 'description' => 'OK' }), strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::ResponseSummaryBefore32.new(root.openapi_version).check(root)
  end

  context 'with a 3.2 document using a response summary' do
    it 'reports no violation' do
      expect(run_rule_for(doc_with('3.2.0'))).to eq []
    end
  end

  context 'with a 3.2 document without a response summary' do
    it 'reports no violation' do
      expect(run_rule_for(doc_without('3.2.0'))).to eq []
    end
  end

  context 'with a 3.1 document using a response summary' do
    it 'reports one violation pointing at the field' do
      violations = run_rule_for(doc_with('3.1.0'))
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/paths/~1pets/get/responses/200/summary'
      expect(violations.first.rule_name).to eq :response_summary_before32
    end
  end

  context 'with a 3.1 document without a response summary' do
    it 'reports no violation' do
      expect(run_rule_for(doc_without('3.1.0'))).to eq []
    end
  end

  context 'with a 3.0 document using a response summary' do
    it 'reports one violation' do
      expect(run_rule_for(doc_with('3.0.0')).size).to eq 1
    end
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)' do
      expect(run_rule_for(doc_with('not-a-version'))).to eq []
    end
  end
end

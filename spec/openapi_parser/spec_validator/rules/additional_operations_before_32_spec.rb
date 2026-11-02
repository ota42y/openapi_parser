require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::AdditionalOperationsBefore32' do
  def base_doc(openapi_version_string, path_item)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => { '/pets' => path_item },
    }
  end

  def doc_with_additional_operations(openapi_version_string)
    path_item = {
      'additionalOperations' => {
        'COPY' => { 'responses' => { '200' => { 'description' => 'OK' } } },
      },
    }
    OpenAPIParser.parse(base_doc(openapi_version_string, path_item), strict_reference_validation: false)
  end

  def doc_without_additional_operations(openapi_version_string)
    path_item = { 'get' => { 'responses' => { '200' => { 'description' => 'OK' } } } }
    OpenAPIParser.parse(base_doc(openapi_version_string, path_item), strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::AdditionalOperationsBefore32.new(root.openapi_version).check(root)
  end

  context 'with a 3.2 document using additionalOperations' do
    it 'reports no violation' do
      root = doc_with_additional_operations('3.2.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.2 document without additionalOperations' do
    it 'reports no violation' do
      root = doc_without_additional_operations('3.2.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document using additionalOperations' do
    it 'reports one violation pointing at the path item' do
      root = doc_with_additional_operations('3.1.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/paths/~1pets/additionalOperations'
      expect(violations.first.rule_name).to eq :additional_operations_before32
    end
  end

  context 'with a 3.1 document without additionalOperations' do
    it 'reports no violation' do
      root = doc_without_additional_operations('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using additionalOperations' do
    it 'reports one violation' do
      root = doc_with_additional_operations('3.0.0')
      expect(run_rule_for(root).size).to eq 1
    end
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)' do
      root = doc_with_additional_operations('not-a-version')
      expect(run_rule_for(root)).to eq []
    end
  end
end

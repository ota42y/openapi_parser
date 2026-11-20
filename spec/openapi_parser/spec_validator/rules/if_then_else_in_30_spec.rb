require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::IfThenElseIn30' do
  def base_doc(openapi_version_string, sample_schema)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => { 'Sample' => sample_schema } },
    }
  end

  def doc_with_schema(openapi_version_string, sample_schema)
    OpenAPIParser.parse(base_doc(openapi_version_string, sample_schema), strict_reference_validation: false)
  end

  def doc_with_if_then_else(openapi_version_string)
    doc_with_schema(
      openapi_version_string,
      {
        'type' => 'object',
        'if' => { 'required' => ['card_number'] },
        'then' => { 'required' => ['expiry'] },
        'else' => { 'required' => ['account_number'] },
      },
    )
  end

  def doc_without_if_then_else(openapi_version_string)
    doc_with_schema(openapi_version_string, { 'type' => 'string' })
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::IfThenElseIn30.new(root.openapi_version).check(root)
  end

  context 'with a 3.1 document using if, then and else' do
    it 'reports no violation' do
      root = doc_with_if_then_else('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document without if, then and else' do
    it 'reports no violation' do
      root = doc_without_if_then_else('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using if, then and else' do
    it 'reports one violation pointing at the offending schema' do
      root = doc_with_if_then_else('3.0.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/components/schemas/Sample'
      expect(violations.first.rule_name).to eq :if_then_else_in30
      expect(violations.first.message).to include('`if`', '`then`', '`else`')
    end
  end

  context 'with a 3.0 document without if, then and else' do
    it 'reports no violation' do
      root = doc_without_if_then_else('3.0.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using only one of the keywords' do
    it 'reports then without if' do
      root = doc_with_schema('3.0.0', { 'type' => 'object', 'then' => { 'required' => ['expiry'] } })
      expect(run_rule_for(root).map(&:path)).to eq ['#/components/schemas/Sample']
    end

    it 'reports else without if' do
      root = doc_with_schema('3.0.0', { 'type' => 'object', 'else' => { 'required' => ['expiry'] } })
      expect(run_rule_for(root).map(&:path)).to eq ['#/components/schemas/Sample']
    end
  end

  context 'with a 3.0 document using a property named if' do
    it 'reports no violation' do
      root = doc_with_schema('3.0.0', { 'type' => 'object', 'properties' => { 'if' => { 'type' => 'string' } } })
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)' do
      root = doc_with_if_then_else('not-a-version')
      expect(run_rule_for(root)).to eq []
    end
  end
end

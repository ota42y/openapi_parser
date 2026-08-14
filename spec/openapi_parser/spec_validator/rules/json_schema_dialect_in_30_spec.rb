require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::JsonSchemaDialectIn30' do
  def base_doc(openapi_version_string)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
    }
  end

  def doc_with_dialect(openapi_version_string)
    raw = base_doc(openapi_version_string)
    raw['jsonSchemaDialect'] = 'https://spec.openapis.org/oas/3.1/dialect/base'
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def doc_without_dialect(openapi_version_string)
    OpenAPIParser.parse(base_doc(openapi_version_string), strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::JsonSchemaDialectIn30.new(root.openapi_version).check(root)
  end

  context 'with a 3.1 document declaring jsonSchemaDialect' do
    it 'reports no violation' do
      root = doc_with_dialect('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document without jsonSchemaDialect' do
    it 'reports no violation' do
      root = doc_without_dialect('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document declaring jsonSchemaDialect' do
    it 'reports one violation pointing at #/jsonSchemaDialect' do
      root = doc_with_dialect('3.0.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/jsonSchemaDialect'
      expect(violations.first.rule_name).to eq :json_schema_dialect_in30
    end
  end

  context 'with a 3.0 document without jsonSchemaDialect' do
    it 'reports no violation' do
      root = doc_without_dialect('3.0.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with an :unknown version document' do
    it 'reports no violation (rule skipped)' do
      root = doc_with_dialect('4.0.0')
      expect(run_rule_for(root)).to eq []
    end
  end
end

RSpec.describe 'OpenAPI#json_schema_dialect parse layer' do
  let(:root) do
    raw = {
      'openapi' => '3.1.0',
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'jsonSchemaDialect' => 'https://spec.openapis.org/oas/3.1/dialect/base',
    }
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  it 'exposes the dialect URI string' do
    expect(root.json_schema_dialect).to eq 'https://spec.openapis.org/oas/3.1/dialect/base'
  end
end

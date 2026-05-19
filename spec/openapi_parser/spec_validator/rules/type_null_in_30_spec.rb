require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::TypeNullIn30' do
  def schema_with_type_null(openapi_version_string)
    raw = {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => { 'Sample' => { 'type' => 'null' } } },
    }
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::TypeNullIn30.new(root.openapi_version).check(root)
  end

  context 'with a 3.1 document using type: "null"' do
    it 'reports no violation'
  end

  context 'with a 3.0 document using type: "null"' do
    it 'reports one violation pointing at the offending schema'
  end

  context 'with a 3.0 document using a normal type' do
    it 'reports no violation'
  end

  context 'with an :unknown version document using type: "null"' do
    it 'reports no violation (rule skipped)'
  end
end

RSpec.describe 'runtime: type: "null" semantic' do
  let(:options) { ::OpenAPIParser::SchemaValidator::Options.new }
  let(:schema) do
    raw = {
      'openapi' => '3.1.0',
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => { 'Nullable' => { 'type' => 'null' } } },
    }
    OpenAPIParser.parse(raw, strict_reference_validation: false).components.schemas['Nullable']
  end

  context 'when value is nil' do
    it 'passes validation without nullable'
  end

  context 'when value is not nil' do
    it 'raises a type-mismatch error'
  end
end

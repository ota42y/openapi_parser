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
    it 'reports no violation' do
      root = schema_with_type_null('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using type: "null"' do
    it 'reports one violation pointing at the offending schema' do
      root = schema_with_type_null('3.0.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/components/schemas/Sample'
      expect(violations.first.rule_name).to eq :type_null_in30
    end
  end

  context 'with a 3.0 document using a normal type' do
    it 'reports no violation' do
      raw = {
        'openapi' => '3.0.0',
        'info' => { 'title' => 'test', 'version' => '1.0' },
        'paths' => {},
        'components' => { 'schemas' => { 'Sample' => { 'type' => 'string' } } },
      }
      root = OpenAPIParser.parse(raw, strict_reference_validation: false)
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with an :unknown version document using type: "null"' do
    it 'reports no violation (rule skipped)' do
      root = schema_with_type_null('4.0.0')
      expect(run_rule_for(root)).to eq []
    end
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
    it 'passes validation without nullable' do
      result = OpenAPIParser::SchemaValidator.validate(nil, schema, options)
      expect(result).to eq nil
    end
  end

  context 'when value is not nil' do
    it 'raises a type-mismatch error' do
      expect do
        OpenAPIParser::SchemaValidator.validate('not nil', schema, options)
      end.to raise_error(OpenAPIParser::ValidateError)
    end
  end
end

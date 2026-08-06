require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::TypeArrayIn30' do
  def schema_with_type_array(openapi_version_string, types)
    raw = {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => { 'Sample' => { 'type' => types } } },
    }
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::TypeArrayIn30.new(root.openapi_version).check(root)
  end

  context 'with a 3.1 document using type as Array' do
    it 'reports no violation' do
      root = schema_with_type_array('3.1.0', ['string', 'null'])
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using type as Array' do
    it 'reports one violation pointing at the offending schema' do
      root = schema_with_type_array('3.0.0', ['string', 'null'])
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/components/schemas/Sample'
      expect(violations.first.rule_name).to eq :type_array_in30
    end
  end

  context 'with a 3.0 document using type as plain string' do
    it 'reports no violation' do
      root = schema_with_type_array('3.0.0', 'string')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with an :unknown version document using type as Array' do
    it 'reports no violation (rule skipped)' do
      root = schema_with_type_array('4.0.0', ['string', 'null'])
      expect(run_rule_for(root)).to eq []
    end
  end
end

RSpec.describe 'runtime: type as Array semantic in 3.1' do
  let(:options) { ::OpenAPIParser::SchemaValidator::Options.new }
  let(:schema) do
    raw = {
      'openapi' => '3.1.0',
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => { 'NullableString' => { 'type' => ['string', 'null'] } } },
    }
    OpenAPIParser.parse(raw, strict_reference_validation: false).components.schemas['NullableString']
  end

  context 'when value is nil and array contains "null"' do
    it 'passes validation' do
      expect(OpenAPIParser::SchemaValidator.validate(nil, schema, options)).to eq nil
    end
  end

  context 'when value matches one of the listed types' do
    it 'passes validation' do
      expect(OpenAPIParser::SchemaValidator.validate('hello', schema, options)).to eq 'hello'
    end
  end

  context 'when value matches no listed type' do
    it 'raises a type-mismatch error' do
      expect do
        OpenAPIParser::SchemaValidator.validate(42, schema, options)
      end.to raise_error(OpenAPIParser::ValidateError)
    end
  end
end

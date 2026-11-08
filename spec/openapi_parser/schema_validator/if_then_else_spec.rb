require_relative '../../spec_helper'

RSpec.describe 'if, then and else keywords' do
  let(:options) { ::OpenAPIParser::SchemaValidator::Options.new }
  let(:openapi_version) { '3.1.0' }
  let(:root) do
    raw = {
      'openapi' => openapi_version,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => schemas },
    }
    OpenAPIParser.parse(raw, strict_reference_validation: true)
  end
  let(:schema) { root.components.schemas['Target'] }

  def validate(value, validate_options = options)
    OpenAPIParser::SchemaValidator.validate(value, schema, validate_options)
  end

  context 'when if, then and else are given' do
    it 'checks then for a value that passes if'
    it 'accepts a value that passes if and then'
    it 'checks else for a value that fails if'
    it 'accepts a value that fails if and passes else'
  end

  context 'when if and then are given' do
    it 'checks then for a value that passes if'
    it 'accepts a value that fails if'
  end

  context 'when if and else are given' do
    it 'checks else for a value that fails if'
    it 'accepts a value that passes if'
  end

  context 'when the keywords are next to type' do
    it 'checks type'
    it 'checks then'
  end

  context 'when the keywords are in a nested schema' do
    it 'reports the error from the nested schema'
  end

  context 'when the keywords are next to allOf' do
    it 'checks allOf'
    it 'checks then'
  end

  context 'when if is a $ref' do
    it 'checks the referenced schema'
  end

  context 'when coerce_value is enabled' do
    it 'checks if with the value coerced by type'
    it 'coerces the value while checking if'
    it 'keeps the value coerced by if in the Hash'
  end

  context 'with a 3.0 document' do
    it 'checks the keywords in the same way'
  end

  context 'when if is a boolean schema' do
    it 'always checks then for true'
    it 'always checks else for false'
  end

  context 'when then or else is a boolean schema' do
    it 'rejects any value with false'
  end

  context 'when only if is given' do
    it 'accepts a value that fails if'
  end

  context 'when then is given without if' do
    it 'ignores then'
  end

  context 'when else is given without if' do
    it 'ignores else'
  end
end

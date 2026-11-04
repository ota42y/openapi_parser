require_relative '../../spec_helper'

RSpec.describe 'dependentRequired keyword' do
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

  def validate(value)
    OpenAPIParser::SchemaValidator.validate(value, schema, options)
  end

  context 'when one property depends on another' do
    it 'rejects a value that has the property but not the one it depends on'
    it 'accepts a value that has both properties'
    it 'accepts a value that has neither property'
    it 'accepts a value that has only the property depended on'
  end

  context 'when a property depends on several properties' do
    it 'reports all the missing properties'
  end

  context 'when several properties have dependencies' do
    it 'checks each of them'
  end

  context 'when the property has a null value' do
    it 'treats the property as present'
  end

  context 'when the schema has no type' do
    it 'checks an object'
    it 'ignores a value that is not an object'
  end

  context 'when the keyword is in allOf' do
    it 'checks the keyword'
  end

  context 'when the keyword is in a nested schema' do
    it 'checks the keyword'
  end

  context 'with a 3.0 document' do
    it 'checks the keyword in the same way'
  end

  context 'when the keyword is not an object' do
    it 'ignores the keyword'
  end

  context 'when a dependency is not an array' do
    it 'ignores the dependency'
  end
end

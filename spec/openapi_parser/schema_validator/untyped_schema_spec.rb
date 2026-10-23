require_relative '../../spec_helper'

RSpec.describe 'schema without type' do
  let(:options) { ::OpenAPIParser::SchemaValidator::Options.new }
  let(:openapi_version) { '3.1.0' }
  let(:root) do
    raw = {
      'openapi' => openapi_version,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => { 'Target' => target } },
    }
    OpenAPIParser.parse(raw, strict_reference_validation: true)
  end
  let(:schema) { root.components.schemas['Target'] }

  def validate(value)
    OpenAPIParser::SchemaValidator.validate(value, schema, options)
  end

  context 'when the value is an object' do
    it 'rejects a property that does not match its schema'
    it 'rejects an object without a required property'
    it 'accepts an object that matches properties and required'
  end

  context 'when the value is an array' do
    it 'rejects an item that does not match items'
  end

  context 'when the value is a string' do
    it 'rejects a string longer than maxLength'
    it 'rejects a string not in enum'
  end

  context 'when the value is a number' do
    it 'rejects an integer below minimum'
    it 'rejects a float below minimum'
  end

  context 'when the value is a boolean' do
    it 'rejects a boolean not in enum'
  end

  context 'when the keywords are for another type' do
    it 'accepts a string for properties and required'
    it 'accepts an object for maxLength'
  end

  context 'when the document is OpenAPI 3.0' do
    it 'rejects a property that does not match its schema'
  end
end

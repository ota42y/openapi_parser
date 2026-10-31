require_relative '../../spec_helper'

RSpec.describe 'not keyword' do
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

  context 'when not forbids a property' do
    let(:schemas) { { 'Target' => { 'type' => 'object', 'not' => { 'required' => ['legacy'] } } } }

    it 'rejects an object with the property' do
      expect { validate({ 'legacy' => 1 }) }.to raise_error(OpenAPIParser::NotSchemaMatched, %r{#/components/schemas/Target/not})
    end

    it 'accepts an object without the property'
  end

  context 'when not excludes a type' do
    it 'rejects a value of the type'

    it 'accepts a value of another type'
  end

  context 'when not excludes an enum value' do
    it 'rejects the value'

    it 'accepts another value'
  end

  context 'when not refers to another schema with $ref' do
    it 'rejects a value valid against the referenced schema'
  end

  context 'when not is an empty schema' do
    it 'rejects any value'
  end

  context 'when the document is OpenAPI 3.0' do
    it 'rejects a value valid against the not schema'
  end

  context 'when reading the parsed schema' do
    it 'returns the not schema as a Schema'
  end
end

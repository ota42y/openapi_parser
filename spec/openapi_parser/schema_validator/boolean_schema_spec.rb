require_relative '../../spec_helper'

RSpec.describe 'boolean schema (3.1)' do
  let(:options) { ::OpenAPIParser::SchemaValidator::Options.new }
  let(:root) do
    raw = {
      'openapi' => '3.1.0',
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

  context 'when items is false after prefixItems' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'array',
          'prefixItems' => [{ 'type' => 'number' }, { 'type' => 'number' }],
          'items' => false,
        },
      }
    end

    it 'accepts an array that matches the prefix' do
      expect(validate([1.5, 2])).to eq [1.5, 2]
    end

    it 'rejects an element past the prefix' do
      expect { validate([1.5, 2, 3]) }.to raise_error(OpenAPIParser::FalseSchemaError, %r{#/components/schemas/Target/items does not allow any value})
    end
  end

  context 'when a property schema is false' do
    it 'rejects the property'
    it 'accepts an object without the property'
  end

  context 'when a property schema is true' do
    it 'accepts any value for the property'
    it 'accepts null for the property'
  end

  context 'when a $ref points to a boolean schema' do
    it 'validates with the referenced boolean schema'
  end

  context 'when the request body schema itself is false' do
    it 'rejects any body'
  end

  context 'when reading the parsed schema' do
    it 'returns a Schema whose raw_schema is the boolean'
  end
end

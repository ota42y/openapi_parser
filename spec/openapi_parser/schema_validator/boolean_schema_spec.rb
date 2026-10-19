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
    let(:schemas) { { 'Target' => { 'type' => 'object', 'properties' => { 'legacy' => false } } } }

    it 'rejects the property' do
      expect { validate({ 'legacy' => 1 }) }.to raise_error(OpenAPIParser::FalseSchemaError, %r{#/components/schemas/Target/properties/legacy})
    end

    it 'accepts an object without the property' do
      expect(validate({ 'name' => 'a' })).to eq({ 'name' => 'a' })
    end
  end

  context 'when a property schema is true' do
    let(:schemas) { { 'Target' => { 'type' => 'object', 'properties' => { 'extra' => true } } } }

    it 'accepts any value for the property' do
      expect(validate({ 'extra' => [1, 'a'] })).to eq({ 'extra' => [1, 'a'] })
    end

    it 'accepts null for the property' do
      expect(validate({ 'extra' => nil })).to eq({ 'extra' => nil })
    end
  end

  context 'when a $ref points to a boolean schema' do
    let(:schemas) do
      {
        'Never' => false,
        'Target' => { 'type' => 'object', 'properties' => { 'legacy' => { '$ref' => '#/components/schemas/Never' } } },
      }
    end

    it 'validates with the referenced boolean schema' do
      expect { validate({ 'legacy' => 1 }) }.to raise_error(OpenAPIParser::FalseSchemaError, %r{#/components/schemas/Never})
    end
  end

  context 'when the request body schema itself is false' do
    let(:root) do
      raw = {
        'openapi' => '3.1.0',
        'info' => { 'title' => 'test', 'version' => '1.0' },
        'paths' => {
          '/items' => {
            'post' => {
              'requestBody' => { 'content' => { 'application/json' => { 'schema' => false } } },
              'responses' => { '204' => { 'description' => 'ok' } },
            },
          },
        },
      }
      OpenAPIParser.parse(raw, strict_reference_validation: true)
    end

    it 'rejects any body' do
      operation = root.request_operation(:post, '/items')
      expect do
        operation.validate_request_body('application/json', { 'name' => 'a' })
      end.to raise_error(OpenAPIParser::FalseSchemaError)
    end
  end

  context 'when reading the parsed schema' do
    let(:schemas) { { 'Target' => { 'type' => 'array', 'items' => false } } }

    it 'returns a Schema whose raw_schema is the boolean' do
      expect(schema.items).to be_a(OpenAPIParser::Schemas::Schema)
      expect(schema.items.raw_schema).to eq false
    end
  end
end

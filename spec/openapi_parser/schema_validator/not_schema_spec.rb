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

    it 'accepts an object without the property' do
      expect(validate({ 'current' => 1 })).to eq({ 'current' => 1 })
    end
  end

  context 'when not excludes a type' do
    let(:schemas) { { 'Target' => { 'not' => { 'type' => 'string' } } } }

    it 'rejects a value of the type' do
      expect { validate('a') }.to raise_error(OpenAPIParser::NotSchemaMatched)
    end

    it 'accepts a value of another type' do
      expect(validate(1)).to eq 1
    end
  end

  context 'when not excludes an enum value' do
    let(:schemas) { { 'Target' => { 'type' => 'string', 'not' => { 'enum' => ['a'] } } } }

    it 'rejects the value' do
      expect { validate('a') }.to raise_error(OpenAPIParser::NotSchemaMatched)
    end

    it 'accepts another value' do
      expect(validate('b')).to eq 'b'
    end
  end

  context 'when not refers to another schema with $ref' do
    let(:schemas) do
      {
        'Target' => { 'not' => { '$ref' => '#/components/schemas/Text' } },
        'Text' => { 'type' => 'string' },
      }
    end

    it 'rejects a value valid against the referenced schema' do
      expect { validate('a') }.to raise_error(OpenAPIParser::NotSchemaMatched)
    end
  end

  context 'when not is an empty schema' do
    let(:schemas) { { 'Target' => { 'not' => {} } } }

    it 'rejects any value' do
      expect { validate(1) }.to raise_error(OpenAPIParser::NotSchemaMatched)
    end
  end

  context 'when the document is OpenAPI 3.0' do
    let(:openapi_version) { '3.0.3' }
    let(:schemas) { { 'Target' => { 'type' => 'object', 'not' => { 'required' => ['legacy'] } } } }

    it 'rejects a value valid against the not schema' do
      expect { validate({ 'legacy' => 1 }) }.to raise_error(OpenAPIParser::NotSchemaMatched)
    end
  end

  context 'when reading the parsed schema' do
    let(:schemas) { { 'Target' => { 'not' => { 'type' => 'string' } } } }

    it 'returns the not schema as a Schema' do
      expect(schema.not).to be_a(OpenAPIParser::Schemas::Schema)
      expect(schema.not.type).to eq 'string'
    end
  end
end

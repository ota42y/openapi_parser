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
    let(:target) { { 'required' => ['count'], 'properties' => { 'count' => { 'type' => 'integer' } } } }

    it 'rejects a property that does not match its schema' do
      expect { validate({ 'count' => 'x' }) }.to raise_error(OpenAPIParser::ValidateError, %r{#/components/schemas/Target/properties/count})
    end

    it 'rejects an object without a required property' do
      expect { validate({}) }.to raise_error(OpenAPIParser::NotExistRequiredKey, /count/)
    end

    it 'accepts an object that matches properties and required' do
      expect(validate({ 'count' => 1 })).to eq({ 'count' => 1 })
    end
  end

  context 'when the value is an array' do
    let(:target) { { 'items' => { 'type' => 'integer' } } }

    it 'rejects an item that does not match items' do
      expect { validate(['x']) }.to raise_error(OpenAPIParser::ValidateError, %r{#/components/schemas/Target/items})
    end
  end

  context 'when the value is a string' do
    let(:target) { { 'maxLength' => 1, 'enum' => ['a', 'abc'] } }

    it 'rejects a string longer than maxLength' do
      expect { validate('abc') }.to raise_error(OpenAPIParser::MoreThanMaxLength)
    end

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

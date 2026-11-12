require_relative '../../spec_helper'

RSpec.describe 'enum for objects and arrays' do
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

  def validate(value, opts = options)
    OpenAPIParser::SchemaValidator.validate(value, schema, opts)
  end

  describe 'an object' do
    context 'when the value equals a member' do
      it 'accepts the value'
    end

    context 'when a property value differs from every member' do
      it 'rejects the value'
    end

    context 'when the keys are in a different order' do
      it 'accepts the value'
    end

    context 'when the value lacks a key or has an extra key' do
      it 'rejects the value'
    end

    context 'when a nested number is written as 1.0' do
      it 'accepts the value'
    end
  end

  describe 'an array' do
    context 'when the value equals a member' do
      it 'accepts the value'
    end

    context 'when an element differs from every member' do
      it 'rejects the value'
    end

    context 'when the elements are in a different order' do
      it 'rejects the value'
    end

    context 'when enum lists the values meant for items' do
      it 'rejects every array'
    end

    context 'when the member has false and the value has 0' do
      it 'rejects the value'
    end
  end

  describe 'a schema without type' do
    context 'when the value is an object or an array' do
      it 'checks enum'
    end
  end

  describe 'an empty enum' do
    context 'when the value is an object or an array' do
      it 'rejects the value'
    end
  end

  describe 'with coerce_value' do
    context 'when the coerced value equals a member' do
      it 'accepts the value and returns the coerced value'
    end
  end

  describe 'in an OpenAPI 3.0 document' do
    context 'when the value differs from every member' do
      it 'rejects the value'
    end
  end
end

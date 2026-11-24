require_relative '../../spec_helper'

RSpec.describe 'coerce_value in a check that can fail without failing the value' do
  let(:options) { ::OpenAPIParser::SchemaValidator::Options.new(coerce_value: true) }
  let(:root) do
    raw = {
      'openapi' => '3.1.0',
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => { 'Target' => target } },
    }
    OpenAPIParser.parse(raw, strict_reference_validation: true)
  end
  let(:schema) { root.components.schemas['Target'] }

  def validate(value, validate_options = options)
    OpenAPIParser::SchemaValidator.validate(value, schema, validate_options)
  end

  context 'when an anyOf member fails after coercing a nested property' do
    it 'checks the next member with the original value'
    it 'leaves the input unchanged'
  end

  context 'when an anyOf member passes' do
    it 'keeps the values coerced by the member in the input'
  end

  context 'when an anyOf member fails after coercing a property on the same level' do
    it 'checks the next member with the original value'
  end

  context 'when an anyOf member fails after coercing an item of a nested Array' do
    it 'checks the next member with the original value'
  end

  context 'when a oneOf member fails after coercing a nested property' do
    it 'checks the other members with the original value'
  end

  context 'when the not subschema fails after coercing a nested property' do
    it 'checks the keywords next to not with the original value'
  end

  context 'when if fails after coercing a nested property' do
    it 'checks else with the original value'
  end

  context 'when an item fails contains after coercing a nested property' do
    it 'checks items with the original value'
  end

  context 'when an item passes contains' do
    it 'keeps the item uncoerced'
  end
end

require_relative '../../spec_helper'

RSpec.describe 'keywords next to allOf, anyOf and oneOf' do
  let(:openapi_version) { '3.1.0' }
  let(:options) { ::OpenAPIParser::SchemaValidator::Options.new }
  let(:coerce_options) { ::OpenAPIParser::SchemaValidator::Options.new(coerce_value: true) }
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

  context 'when a keyword is next to allOf' do
    it 'rejects a value that breaks the keyword'
    it 'accepts a value that satisfies both'
    it 'rejects a value that breaks allOf'
  end

  context 'when a keyword is next to anyOf' do
    it 'rejects a value that breaks the keyword'
    it 'accepts a value that satisfies both'
  end

  context 'when a keyword is next to oneOf' do
    it 'rejects a value that breaks the keyword'
    it 'accepts a value that satisfies both'
  end

  context 'when type and required are next to a composition keyword' do
    it 'rejects an object without the required property'
    it 'rejects a value of another type'
  end

  context 'when two composition keywords are in one schema' do
    it 'checks allOf and oneOf'
    it 'checks anyOf and allOf'
    it 'checks anyOf and oneOf'
  end

  context 'when properties are next to allOf' do
    it 'checks the properties'
    it 'accepts the properties of both'
  end

  context 'when additionalProperties: false is next to allOf' do
    it 'rejects a property defined only in allOf'
    it 'accepts a property defined next to it'
  end

  context 'when the schema is a member of allOf' do
    it 'checks its keywords'
  end

  context 'when discriminator is next to oneOf with other keywords' do
    it 'selects the schema with discriminator'
    it 'checks the other keywords'
  end

  context 'when nullable is next to a composition keyword' do
    it 'accepts null'
    it 'rejects null when type does not allow it'
  end

  context 'with a 3.0 document' do
    it 'checks the keyword in the same way'
  end

  context 'with coerce_value' do
    context 'when allOf has a member with type' do
      it 'returns the coerced value'
      it 'checks the other members with the coerced value'
      it 'checks a member without type that comes before it'
    end

    context 'when oneOf has a member with type' do
      it 'returns the coerced value'
    end

    context 'when a keyword is next to a composition keyword with type' do
      it 'checks the keyword with the coerced value'
      it 'returns the coerced value'
    end

    context 'when type is next to a composition keyword without type' do
      it 'checks the composition keyword with the coerced value'
      it 'compares enum with the coerced value'
    end

    context 'when an object is coerced' do
      it 'coerces the property'
      it 'checks a keyword next to it with the coerced property'
    end

    context 'when a date-time is coerced' do
      it 'returns the DateTime'
      it 'checks a keyword next to it with the original string'
      it 'checks a member of allOf with the original string'
    end
  end
end

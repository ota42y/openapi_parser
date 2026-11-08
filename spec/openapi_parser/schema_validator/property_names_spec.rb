require_relative '../../spec_helper'

RSpec.describe 'propertyNames keyword' do
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

  def validate(value, validate_options = options)
    OpenAPIParser::SchemaValidator.validate(value, schema, validate_options)
  end

  context 'when property names must match a pattern' do
    it 'accepts a value whose names all match'
    it 'rejects a value that has a name that does not match'
    it 'accepts an empty object'
  end

  context 'when property names have a maximum length' do
    it 'accepts a value whose names are short enough'
    it 'rejects a value that has a name that is too long'
  end

  context 'when property names are limited by enum' do
    it 'accepts a value whose names are listed'
    it 'rejects a value that has a name that is not listed'
  end

  context 'when the schema also has properties' do
    it 'checks the names of the declared properties too'
  end

  context 'when the property names schema is a reference' do
    it 'checks the names against the referenced schema'
  end

  context 'when the schema has no type' do
    it 'checks an object'
    it 'ignores a value that is not an object'
  end

  context 'when the keyword is in a nested schema' do
    it 'checks the keyword'
  end

  context 'when the property names schema is false' do
    it 'rejects a value that has any property'
    it 'accepts an empty object'
  end

  context 'when the property names schema is true' do
    it 'accepts a value that has any property'
  end

  context 'when the property names schema requires an integer' do
    it 'rejects a value whose name looks like an integer'
    it 'rejects the name with coerce_value too'
    it 'accepts an empty object'
  end

  context 'with a 3.0 document' do
    it 'checks the keyword in the same way'
  end
end

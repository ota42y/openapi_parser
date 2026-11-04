require_relative '../../spec_helper'

RSpec.describe 'keywords next to $ref' do
  let(:openapi_version) { '3.1.0' }
  let(:strict_reference_validation) { true }
  let(:options) { ::OpenAPIParser::SchemaValidator::Options.new }
  let(:coerce_options) { ::OpenAPIParser::SchemaValidator::Options.new(coerce_value: true) }
  let(:base_schemas) do
    {
      'Name' => { 'type' => 'string' },
      'Count' => { 'type' => 'integer' },
      'Item' => { 'type' => 'object', 'properties' => { 'id' => { 'type' => 'integer' } } },
    }
  end
  let(:root) do
    raw = {
      'openapi' => openapi_version,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => paths,
      'components' => { 'schemas' => base_schemas.merge('Target' => target) },
    }
    OpenAPIParser.parse(raw, strict_reference_validation: strict_reference_validation)
  end
  let(:paths) { {} }
  let(:schema) { root.components.schemas['Target'] }

  def validate(value, validate_options = options)
    OpenAPIParser::SchemaValidator.validate(value, schema, validate_options)
  end

  context 'when a keyword is next to $ref' do
    it 'rejects a value that breaks the keyword'
    it 'accepts a value that satisfies both'
    it 'rejects a value that breaks the referenced schema'
    it 'reports the path of the schema'
  end

  context 'when required is next to $ref' do
    it 'rejects an object without the property'
  end

  context 'when properties are next to $ref' do
    it 'checks the properties'
  end

  context 'when additionalProperties: false is next to $ref' do
    it 'rejects a property defined only in the referenced schema'
  end

  context 'when only annotations are next to $ref' do
    it 'is the referenced schema'
  end

  context 'when code reads the schema' do
    it 'returns the type of the referenced schema'
    it 'returns the properties of the referenced schema'
  end

  context 'when the schema is in other places' do
    it 'checks a property'
    it 'checks items'
    it 'checks a member of allOf'
    it 'checks a member of anyOf'
    it 'checks a member of oneOf'
  end

  context 'when the referenced schema also has a keyword next to $ref' do
    it 'checks both'
  end

  context 'when a composition keyword is next to $ref' do
    it 'checks allOf'
    it 'checks oneOf'
  end

  context 'with a 3.0 document' do
    it 'ignores the keyword'
    it 'is the referenced schema'
  end

  context 'when it is not a Schema Object' do
    it 'ignores the keyword next to $ref'
  end

  context 'with coerce_value' do
    it 'checks the keyword with the coerced value'
    it 'returns the coerced value'
    it 'coerces with type next to a $ref without type'
    it 'returns the DateTime and checks the keyword with the original string'
  end

  context 'when the reference cannot be resolved' do
    it 'raises an error with strict_reference_validation'
    it 'checks only the keyword without strict_reference_validation'
  end

  context 'when $ref points into the keywords next to $ref' do
    it 'resolves the reference'
  end

  context 'with SpecValidator' do
    it 'reports a keyword next to $ref once'
  end
end

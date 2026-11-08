require_relative '../../spec_helper'

RSpec.describe 'patternProperties keyword' do
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

  context 'when a pattern matches some property names' do
    it 'rejects a property whose name matches and whose value does not fit the schema'
    it 'accepts properties whose names match and whose values fit the schema'
    it 'ignores a property whose name does not match'
  end

  context 'when additionalProperties is false' do
    it 'accepts a property whose name matches a pattern'
    it 'rejects a property whose name matches no pattern'
  end

  context 'when properties and patternProperties both apply to a name' do
    it 'checks the value against both schemas'
  end

  context 'when several patterns match one name' do
    it 'checks the value against every matching schema'
  end

  context 'when additionalProperties is a schema' do
    it 'does not apply additionalProperties to a property whose name matches a pattern'
    it 'applies additionalProperties to a property whose name matches no pattern'
  end

  context 'when the pattern is not anchored' do
    it 'matches the pattern anywhere in the name'
    it 'matches the pattern case-sensitively'
  end

  context 'when the schema has no type' do
    it 'checks an object'
    it 'ignores a value that is not an object'
  end

  context 'when coercion is enabled' do
    it 'coerces a value whose name matches'
  end

  context 'when a pattern schema is a reference' do
    it 'checks the value against the referenced schema'
  end

  context 'when a pattern schema is a boolean schema' do
    it 'rejects a property whose name matches the false schema'
  end

  context 'when the keyword is in allOf' do
    it 'checks the keyword'
  end

  context 'when the keyword is in a nested schema' do
    it 'checks the keyword'
  end

  context 'with a 3.0 document' do
    it 'checks the keyword in the same way'
  end

  context 'when a pattern is not a valid regular expression' do
    it 'raises RegexpError as the pattern keyword does'
  end
end

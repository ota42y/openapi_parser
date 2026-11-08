require_relative '../../spec_helper'

RSpec.describe 'dependentSchemas keyword' do
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

  context 'when the subschema requires other properties' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'properties' => { 'credit_card' => { 'type' => 'string' }, 'billing_address' => { 'type' => 'string' } },
          'dependentSchemas' => { 'credit_card' => { 'required' => ['billing_address'] } },
        },
      }
    end

    it 'rejects a value that has the property but not the required ones' do
      expect { validate({ 'credit_card' => 'x' }) }.to raise_error(
        OpenAPIParser::NotExistRequiredKey,
        %r{#/components/schemas/Target/dependentSchemas/credit_card missing required parameters: billing_address},
      )
    end

    it 'accepts a value that has the property and the required ones'
    it 'accepts a value that does not have the property'
  end

  context 'when the subschema checks the types of properties' do
    it 'rejects a value whose other property has the wrong type'
    it 'rejects a value whose property itself has the wrong type'
    it 'accepts a value whose properties have the right types'
    it 'does not check the types when the value does not have the property'
  end

  context 'when several properties have subschemas' do
    it 'checks each of them'
  end

  context 'when the property has a null value' do
    it 'treats the property as present'
  end

  context 'when the subschema is a boolean schema' do
    it 'rejects a value that has a property whose subschema is false'
    it 'accepts a value that has a property whose subschema is true'
    it 'accepts a value that has none of the properties'
  end

  context 'when the subschema does not list every property of the value' do
    it 'accepts the other properties'
  end

  context 'when the subschema does not allow additional properties' do
    it 'rejects a property that the subschema does not list'
    it 'accepts a value that has only the properties the subschema lists'
  end

  context 'when the subschema is a reference' do
    it 'checks the referenced schema'
  end

  context 'with coerce_value' do
    it 'coerces the properties that the subschema checks'
  end

  context 'when the schema has no type' do
    it 'checks an object'
    it 'ignores a value that is not an object'
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
end

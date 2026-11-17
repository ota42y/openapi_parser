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

    it 'accepts a value that has the property and the required ones' do
      value = { 'credit_card' => 'x', 'billing_address' => 'y' }
      expect(validate(value)).to eq value
    end

    it 'accepts a value that does not have the property' do
      value = { 'billing_address' => 'y' }
      expect(validate(value)).to eq value
    end
  end

  context 'when the subschema checks the types of properties' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'dependentSchemas' => {
            'bar' => { 'properties' => { 'foo' => { 'type' => 'integer' }, 'bar' => { 'type' => 'integer' } } },
          },
        },
      }
    end

    it 'rejects a value whose other property has the wrong type' do
      expect { validate({ 'foo' => 'quux', 'bar' => 2 }) }.to raise_error(
        OpenAPIParser::ValidateError,
        %r{#/components/schemas/Target/dependentSchemas/bar/properties/foo},
      )
    end

    it 'rejects a value whose property itself has the wrong type' do
      expect { validate({ 'foo' => 2, 'bar' => 'quux' }) }.to raise_error(
        OpenAPIParser::ValidateError,
        %r{#/components/schemas/Target/dependentSchemas/bar/properties/bar},
      )
    end

    it 'accepts a value whose properties have the right types' do
      value = { 'foo' => 1, 'bar' => 2 }
      expect(validate(value)).to eq value
    end

    it 'does not check the types when the value does not have the property' do
      value = { 'foo' => 'quux' }
      expect(validate(value)).to eq value
    end
  end

  context 'when several properties have subschemas' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'dependentSchemas' => { 'a' => { 'required' => ['b'] }, 'c' => { 'required' => ['d'] } },
        },
      }
    end

    it 'checks each of them' do
      expect { validate({ 'a' => 1, 'b' => 1, 'c' => 1 }) }.to raise_error(
        OpenAPIParser::NotExistRequiredKey,
        %r{#/components/schemas/Target/dependentSchemas/c missing required parameters: d},
      )
    end
  end

  context 'when the property has a null value' do
    let(:schemas) { { 'Target' => { 'type' => 'object', 'dependentSchemas' => { 'a' => { 'required' => ['b'] } } } } }

    it 'treats the property as present' do
      expect { validate({ 'a' => nil }) }.to raise_error(OpenAPIParser::NotExistRequiredKey)
    end
  end

  context 'when the subschema is a boolean schema' do
    let(:schemas) { { 'Target' => { 'type' => 'object', 'dependentSchemas' => { 'foo' => true, 'bar' => false } } } }

    it 'rejects a value that has a property whose subschema is false' do
      expect { validate({ 'bar' => 2 }) }.to raise_error(
        OpenAPIParser::FalseSchemaError,
        %r{#/components/schemas/Target/dependentSchemas/bar},
      )
    end

    it 'accepts a value that has a property whose subschema is true' do
      value = { 'foo' => 1 }
      expect(validate(value)).to eq value
    end

    it 'accepts a value that has none of the properties' do
      expect(validate({})).to eq({})
    end
  end

  context 'when the subschema does not list every property of the value' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'dependentSchemas' => { 'a' => { 'properties' => { 'b' => { 'type' => 'integer' } } } },
        },
      }
    end

    it 'accepts the other properties' do
      value = { 'a' => 1, 'b' => 2, 'c' => 3 }
      expect(validate(value)).to eq value
    end
  end

  context 'when the subschema does not allow additional properties' do
    let(:schemas) do
      {
        'Target' => {
          'properties' => { 'foo' => {} },
          'dependentSchemas' => { 'foo' => { 'properties' => { 'bar' => {} }, 'additionalProperties' => false } },
        },
      }
    end

    it 'rejects a property that the subschema does not list' do
      expect { validate({ 'foo' => 1, 'bar' => 2 }) }.to raise_error(
        OpenAPIParser::NotExistPropertyDefinition,
        %r{#/components/schemas/Target/dependentSchemas/foo does not define properties: foo},
      )
    end

    it 'accepts a value that has only the properties the subschema lists' do
      value = { 'bar' => 1 }
      expect(validate(value)).to eq value
    end
  end

  context 'when the subschema is a reference' do
    let(:schemas) do
      {
        'Target' => { 'type' => 'object', 'dependentSchemas' => { 'a' => { '$ref' => '#/components/schemas/NeedsB' } } },
        'NeedsB' => { 'required' => ['b'] },
      }
    end

    it 'checks the referenced schema' do
      expect { validate({ 'a' => 1 }) }.to raise_error(
        OpenAPIParser::NotExistRequiredKey,
        %r{#/components/schemas/NeedsB missing required parameters: b},
      )
    end
  end

  context 'with coerce_value' do
    let(:options) { ::OpenAPIParser::SchemaValidator::Options.new(coerce_value: true) }
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'properties' => { 'a' => { 'type' => 'integer' } },
          'dependentSchemas' => { 'a' => { 'properties' => { 'b' => { 'type' => 'integer' } } } },
        },
      }
    end

    it 'coerces the properties that the subschema checks' do
      expect(validate({ 'a' => '1', 'b' => '2' })).to eq({ 'a' => 1, 'b' => 2 })
    end
  end

  context 'when the schema has no type' do
    let(:schemas) { { 'Target' => { 'dependentSchemas' => { 'a' => { 'required' => ['b'] } } } } }

    it 'checks an object' do
      expect { validate({ 'a' => 1 }) }.to raise_error(OpenAPIParser::NotExistRequiredKey)
    end

    it 'ignores a value that is not an object' do
      expect(validate('a')).to eq 'a'
    end
  end

  context 'when the keyword is in allOf' do
    let(:schemas) do
      {
        'Target' => {
          'allOf' => [
            { 'type' => 'object', 'properties' => { 'a' => { 'type' => 'integer' } } },
            { 'type' => 'object', 'dependentSchemas' => { 'a' => { 'required' => ['b'] } } },
          ],
        },
      }
    end

    it 'checks the keyword' do
      expect { validate({ 'a' => 1 }) }.to raise_error(OpenAPIParser::NotExistRequiredKey)
    end
  end

  context 'when the keyword is in a nested schema' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'properties' => { 'nested' => { 'type' => 'object', 'dependentSchemas' => { 'a' => { 'required' => ['b'] } } } },
        },
      }
    end

    it 'checks the keyword' do
      expect { validate({ 'nested' => { 'a' => 1 } }) }.to raise_error(
        OpenAPIParser::NotExistRequiredKey,
        %r{#/components/schemas/Target/properties/nested/dependentSchemas/a missing required parameters: b},
      )
    end
  end

  context 'with a 3.0 document' do
    let(:openapi_version) { '3.0.3' }
    let(:schemas) { { 'Target' => { 'type' => 'object', 'dependentSchemas' => { 'a' => { 'required' => ['b'] } } } } }

    it 'checks the keyword in the same way' do
      expect { validate({ 'a' => 1 }) }.to raise_error(OpenAPIParser::NotExistRequiredKey)
    end
  end
end

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
    let(:schemas) { { 'Target' => { 'type' => 'object', 'propertyNames' => { 'pattern' => '^[a-z_]+$' } } } }

    it 'accepts a value whose names all match' do
      value = { 'user_id' => 1, 'user_name' => 'x' }
      expect(validate(value)).to eq value
    end

    it 'rejects a value that has a name that does not match' do
      expect { validate({ 'user_id' => 1, 'userName' => 'x' }) }.to raise_error(
        OpenAPIParser::InvalidPattern,
        %r{#/components/schemas/Target/propertyNames pattern \^\[a-z_\]\+\$ does not match value: "userName"},
      )
    end

    it 'accepts an empty object' do
      expect(validate({})).to eq({})
    end
  end

  context 'when property names have a maximum length' do
    let(:schemas) { { 'Target' => { 'type' => 'object', 'propertyNames' => { 'maxLength' => 3 } } } }

    it 'accepts a value whose names are short enough' do
      value = { 'f' => {}, 'foo' => {} }
      expect(validate(value)).to eq value
    end

    it 'rejects a value that has a name that is too long' do
      expect { validate({ 'foo' => {}, 'foobar' => {} }) }.to raise_error(
        OpenAPIParser::MoreThanMaxLength,
        %r{#/components/schemas/Target/propertyNames "foobar" is longer than max length},
      )
    end
  end

  context 'when property names are limited by enum' do
    let(:schemas) { { 'Target' => { 'type' => 'object', 'propertyNames' => { 'enum' => %w[foo bar] } } } }

    it 'accepts a value whose names are listed' do
      value = { 'foo' => 1, 'bar' => 1 }
      expect(validate(value)).to eq value
    end

    it 'rejects a value that has a name that is not listed' do
      expect { validate({ 'foo' => 1, 'baz' => 1 }) }.to raise_error(OpenAPIParser::NotEnumInclude, /"baz" isn't part of the enum/)
    end
  end

  context 'when the schema also has properties' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'properties' => { 'Name' => { 'type' => 'string' } },
          'propertyNames' => { 'pattern' => '^[a-z]+$' },
        },
      }
    end

    it 'checks the names of the declared properties too' do
      expect { validate({ 'Name' => 'x' }) }.to raise_error(OpenAPIParser::InvalidPattern, /does not match value: "Name"/)
    end
  end

  context 'when the property names schema is a reference' do
    let(:schemas) do
      {
        'Target' => { 'type' => 'object', 'propertyNames' => { '$ref' => '#/components/schemas/Name' } },
        'Name' => { 'type' => 'string', 'pattern' => '^[a-z]+$' },
      }
    end

    it 'checks the names against the referenced schema' do
      expect(validate({ 'foo' => 1 })).to eq({ 'foo' => 1 })
      expect { validate({ 'Foo' => 1 }) }.to raise_error(
        OpenAPIParser::InvalidPattern,
        %r{#/components/schemas/Name pattern},
      )
    end
  end

  context 'when the schema has no type' do
    let(:schemas) { { 'Target' => { 'propertyNames' => { 'maxLength' => 3 } } } }

    it 'checks an object' do
      expect { validate({ 'foobar' => 1 }) }.to raise_error(OpenAPIParser::MoreThanMaxLength)
    end

    it 'ignores a value that is not an object' do
      expect(validate('foobar')).to eq 'foobar'
      expect(validate([1, 2, 3, 4])).to eq [1, 2, 3, 4]
    end
  end

  context 'when the keyword is in a nested schema' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'properties' => { 'nested' => { 'type' => 'object', 'propertyNames' => { 'maxLength' => 3 } } },
        },
      }
    end

    it 'checks the keyword' do
      expect { validate({ 'nested' => { 'foobar' => 1 } }) }.to raise_error(
        OpenAPIParser::MoreThanMaxLength,
        %r{#/components/schemas/Target/properties/nested/propertyNames "foobar" is longer than max length},
      )
    end
  end

  context 'when the property names schema is false' do
    let(:schemas) { { 'Target' => { 'type' => 'object', 'propertyNames' => false } } }

    it 'rejects a value that has any property' do
      expect { validate({ 'foo' => 1 }) }.to raise_error(
        OpenAPIParser::FalseSchemaError,
        %r{#/components/schemas/Target/propertyNames does not allow any value},
      )
    end

    it 'accepts an empty object' do
      expect(validate({})).to eq({})
    end
  end

  context 'when the property names schema is true' do
    let(:schemas) { { 'Target' => { 'type' => 'object', 'propertyNames' => true } } }

    it 'accepts a value that has any property' do
      value = { 'foo' => 1, 'Any Name' => 2 }
      expect(validate(value)).to eq value
    end
  end

  context 'when the property names schema requires an integer' do
    let(:schemas) { { 'Target' => { 'type' => 'object', 'propertyNames' => { 'type' => 'integer' } } } }

    it 'rejects a value whose name looks like an integer' do
      expect { validate({ '5' => 1 }) }.to raise_error(
        OpenAPIParser::ValidateError,
        %r{#/components/schemas/Target/propertyNames expected integer, but received String: "5"},
      )
    end

    it 'rejects the name with coerce_value too' do
      coerce_options = ::OpenAPIParser::SchemaValidator::Options.new(coerce_value: true)
      expect { validate({ '5' => 1 }, coerce_options) }.to raise_error(OpenAPIParser::ValidateError)
    end

    it 'accepts an empty object' do
      expect(validate({})).to eq({})
    end
  end

  context 'with a 3.0 document' do
    let(:openapi_version) { '3.0.3' }
    let(:schemas) { { 'Target' => { 'type' => 'object', 'propertyNames' => { 'maxLength' => 3 } } } }

    it 'checks the keyword in the same way' do
      expect { validate({ 'foobar' => 1 }) }.to raise_error(OpenAPIParser::MoreThanMaxLength)
    end
  end
end

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
    let(:schemas) { { 'Target' => { 'type' => 'object', 'patternProperties' => { '^x-' => { 'type' => 'integer' } } } } }

    it 'rejects a property whose name matches and whose value does not fit the schema' do
      expect { validate({ 'x-a' => 1, 'x-b' => 'two' }) }.to raise_error(
        OpenAPIParser::ValidateError,
        %r{#/components/schemas/Target/patternProperties/\^x- expected integer, but received String: "two"},
      )
    end

    it 'accepts properties whose names match and whose values fit the schema' do
      value = { 'x-a' => 1, 'x-b' => 2 }
      expect(validate(value)).to eq value
    end

    it 'ignores a property whose name does not match' do
      value = { 'name' => 'n', 'x-a' => 1 }
      expect(validate(value)).to eq value
    end
  end

  context 'when additionalProperties is false' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'patternProperties' => { '^x-' => { 'type' => 'integer' } },
          'additionalProperties' => false,
        },
      }
    end

    it 'accepts a property whose name matches a pattern' do
      value = { 'x-a' => 1 }
      expect(validate(value)).to eq value
    end

    it 'rejects a property whose name matches no pattern' do
      expect { validate({ 'x-a' => 1, 'name' => 'n' }) }.to raise_error(
        OpenAPIParser::NotExistPropertyDefinition,
        %r{#/components/schemas/Target does not define properties: name},
      )
    end
  end

  context 'when properties and patternProperties both apply to a name' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'properties' => { 'x-a' => { 'type' => 'integer' } },
          'patternProperties' => { '^x-' => { 'type' => 'integer', 'minimum' => 10 } },
        },
      }
    end

    it 'checks the value against both schemas' do
      expect { validate({ 'x-a' => 'five' }) }.to raise_error(
        OpenAPIParser::ValidateError,
        %r{#/components/schemas/Target/properties/x-a expected integer},
      )
      expect { validate({ 'x-a' => 5 }) }.to raise_error(
        OpenAPIParser::LessThanMinimum,
        %r{#/components/schemas/Target/patternProperties/\^x-},
      )
      value = { 'x-a' => 15 }
      expect(validate(value)).to eq value
    end
  end

  context 'when several patterns match one name' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'patternProperties' => { 'a*' => { 'type' => 'integer' }, 'aaa*' => { 'maximum' => 20 } },
        },
      }
    end

    it 'checks the value against every matching schema' do
      expect(validate({ 'a' => 21, 'aaaa' => 18 })).to eq({ 'a' => 21, 'aaaa' => 18 })
      expect { validate({ 'aaaa' => 31 }) }.to raise_error(
        OpenAPIParser::MoreThanMaximum,
        %r{#/components/schemas/Target/patternProperties/aaa\*},
      )
      expect { validate({ 'aaa' => 'foo' }) }.to raise_error(
        OpenAPIParser::ValidateError,
        %r{#/components/schemas/Target/patternProperties/a\* expected integer},
      )
    end
  end

  context 'when additionalProperties is a schema' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'patternProperties' => { '^x-' => { 'type' => 'integer' } },
          'additionalProperties' => { 'type' => 'string' },
        },
      }
    end

    it 'does not apply additionalProperties to a property whose name matches a pattern' do
      value = { 'x-a' => 1 }
      expect(validate(value)).to eq value
    end

    it 'applies additionalProperties to a property whose name matches no pattern' do
      expect { validate({ 'x-a' => 1, 'name' => 1 }) }.to raise_error(
        OpenAPIParser::ValidateError,
        %r{#/components/schemas/Target/additionalProperties expected string, but received Integer: 1},
      )
    end
  end

  context 'when the pattern is not anchored' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'patternProperties' => { '[0-9]{2,}' => { 'type' => 'boolean' }, 'X_' => { 'type' => 'string' } },
        },
      }
    end

    it 'matches the pattern anywhere in the name' do
      expect { validate({ 'a31b' => 1 }) }.to raise_error(
        OpenAPIParser::ValidateError,
        %r{#/components/schemas/Target/patternProperties/\[0-9\]\{2,\} expected boolean},
      )
    end

    it 'matches the pattern case-sensitively' do
      value = { 'a_x_3' => 3 }
      expect(validate(value)).to eq value
      expect { validate({ 'a_X_3' => 3 }) }.to raise_error(OpenAPIParser::ValidateError, /expected string/)
    end
  end

  context 'when the schema has no type' do
    let(:schemas) { { 'Target' => { 'patternProperties' => { 'f.*o' => { 'type' => 'integer' } } } } }

    it 'checks an object' do
      expect { validate({ 'foo' => 'bar' }) }.to raise_error(OpenAPIParser::ValidateError, /expected integer/)
    end

    it 'ignores a value that is not an object' do
      expect(validate('foo')).to eq 'foo'
      expect(validate(['foo'])).to eq ['foo']
      expect(validate(12)).to eq 12
    end
  end

  context 'when coercion is enabled' do
    let(:options) { ::OpenAPIParser::SchemaValidator::Options.new(coerce_value: true) }
    let(:schemas) { { 'Target' => { 'type' => 'object', 'patternProperties' => { '^x-' => { 'type' => 'integer' } } } } }

    it 'coerces a value whose name matches' do
      expect(validate({ 'x-a' => '1' })).to eq({ 'x-a' => 1 })
    end
  end

  context 'when a pattern schema is a reference' do
    let(:schemas) do
      {
        'Int' => { 'type' => 'integer' },
        'Target' => { 'type' => 'object', 'patternProperties' => { '^x-' => { '$ref' => '#/components/schemas/Int' } } },
      }
    end

    it 'checks the value against the referenced schema' do
      expect { validate({ 'x-a' => 'two' }) }.to raise_error(
        OpenAPIParser::ValidateError,
        %r{#/components/schemas/Int expected integer},
      )
    end
  end

  context 'when a pattern schema is a boolean schema' do
    let(:schemas) { { 'Target' => { 'type' => 'object', 'patternProperties' => { 'f.*' => true, 'b.*' => false } } } }

    it 'rejects a property whose name matches the false schema' do
      expect(validate({ 'foo' => 1 })).to eq({ 'foo' => 1 })
      expect { validate({ 'bar' => 2 }) }.to raise_error(OpenAPIParser::FalseSchemaError)
      expect { validate({ 'foobar' => 1 }) }.to raise_error(OpenAPIParser::FalseSchemaError)
    end
  end

  context 'when the keyword is in allOf' do
    let(:schemas) do
      {
        'Target' => {
          'allOf' => [
            { 'type' => 'object', 'properties' => { 'name' => { 'type' => 'string' } } },
            { 'type' => 'object', 'patternProperties' => { '^x-' => { 'type' => 'integer' } } },
          ],
        },
      }
    end

    it 'checks the keyword' do
      expect { validate({ 'name' => 'n', 'x-a' => 'two' }) }.to raise_error(
        OpenAPIParser::ValidateError,
        %r{#/components/schemas/Target/allOf/1/patternProperties/\^x- expected integer},
      )
    end
  end

  context 'when the keyword is in a nested schema' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'properties' => { 'nested' => { 'type' => 'object', 'patternProperties' => { '^x-' => { 'type' => 'integer' } } } },
        },
      }
    end

    it 'checks the keyword' do
      expect { validate({ 'nested' => { 'x-a' => 'two' } }) }.to raise_error(
        OpenAPIParser::ValidateError,
        %r{#/components/schemas/Target/properties/nested/patternProperties/\^x- expected integer},
      )
    end
  end

  context 'with a 3.0 document' do
    let(:openapi_version) { '3.0.3' }
    let(:schemas) { { 'Target' => { 'type' => 'object', 'patternProperties' => { '^x-' => { 'type' => 'integer' } } } } }

    it 'checks the keyword in the same way' do
      expect { validate({ 'x-a' => 'two' }) }.to raise_error(OpenAPIParser::ValidateError, /expected integer/)
    end
  end

  context 'when a pattern is not a valid regular expression' do
    let(:schemas) { { 'Target' => { 'type' => 'object', 'patternProperties' => { '(' => { 'type' => 'integer' } } } } }

    it 'raises RegexpError as the pattern keyword does' do
      expect { validate({ 'a' => 1 }) }.to raise_error(RegexpError)
    end
  end
end

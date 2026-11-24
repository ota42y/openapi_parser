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
  # Coerces o.a to an Integer, and then fails on b.
  let(:integer_then_fail) do
    {
      'properties' => {
        'o' => { 'properties' => { 'a' => { 'type' => 'integer' } } },
        'b' => { 'type' => 'integer' },
      },
    }
  end
  let(:string) { { 'properties' => { 'o' => { 'properties' => { 'a' => { 'type' => 'string' } } } } } }

  def validate(value, validate_options = options)
    OpenAPIParser::SchemaValidator.validate(value, schema, validate_options)
  end

  context 'when an anyOf member fails after coercing a nested property' do
    let(:target) { { 'anyOf' => [integer_then_fail, string] } }

    it 'checks the next member with the original value' do
      expect(validate({ 'o' => { 'a' => '1' }, 'b' => 'x' })).to eq({ 'o' => { 'a' => '1' }, 'b' => 'x' })
    end

    it 'leaves the input unchanged' do
      value = { 'o' => { 'a' => '1' }, 'b' => 'x' }
      validate(value)
      expect(value).to eq({ 'o' => { 'a' => '1' }, 'b' => 'x' })
    end
  end

  context 'when an anyOf member passes' do
    let(:target) { { 'anyOf' => [integer_then_fail, string] } }

    it 'keeps the values coerced by the member in the input' do
      value = { 'o' => { 'a' => '1' }, 'b' => '2' }
      expect(validate(value)).to eq({ 'o' => { 'a' => 1 }, 'b' => 2 })
      expect(value).to eq({ 'o' => { 'a' => 1 }, 'b' => 2 })
    end
  end

  context 'when an anyOf member fails after coercing a property on the same level' do
    let(:target) do
      {
        'anyOf' => [
          { 'properties' => { 'a' => { 'type' => 'integer' } }, 'maxProperties' => 0 },
          { 'properties' => { 'a' => { 'type' => 'string' } } },
        ],
      }
    end

    it 'checks the next member with the original value' do
      expect(validate({ 'a' => '1' })).to eq({ 'a' => '1' })
    end
  end

  context 'when an anyOf member fails after coercing an item of a nested Array' do
    let(:target) do
      {
        'anyOf' => [
          { 'properties' => { 'l' => { 'items' => { 'type' => 'integer' } }, 'b' => { 'type' => 'integer' } } },
          { 'properties' => { 'l' => { 'items' => { 'type' => 'string' } } } },
        ],
      }
    end

    it 'checks the next member with the original value' do
      expect(validate({ 'l' => ['1'], 'b' => 'x' })).to eq({ 'l' => ['1'], 'b' => 'x' })
    end
  end

  context 'when a oneOf member fails after coercing a nested property' do
    # Needs coercion too, so the value does not match it as it is.
    let(:string_and_integer) { string.merge('properties' => string['properties'].merge('c' => { 'type' => 'integer' })) }
    let(:target) { { 'oneOf' => [integer_then_fail, string_and_integer] } }

    it 'checks the other members with the original value' do
      expect(validate({ 'o' => { 'a' => '1' }, 'b' => 'x', 'c' => '2' })).to eq({ 'o' => { 'a' => '1' }, 'b' => 'x', 'c' => 2 })
    end
  end

  context 'when the not subschema fails after coercing a nested property' do
    let(:target) { { 'not' => integer_then_fail }.merge(string) }

    it 'checks the keywords next to not with the original value' do
      expect(validate({ 'o' => { 'a' => '1' }, 'b' => 'x' })).to eq({ 'o' => { 'a' => '1' }, 'b' => 'x' })
    end
  end

  context 'when if fails after coercing a nested property' do
    let(:target) { { 'if' => integer_then_fail, 'else' => string } }

    it 'checks else with the original value' do
      expect(validate({ 'o' => { 'a' => '1' }, 'b' => 'x' })).to eq({ 'o' => { 'a' => '1' }, 'b' => 'x' })
    end
  end

  context 'when an item fails contains after coercing a nested property' do
    let(:target) do
      {
        'contains' => { 'properties' => { 'a' => { 'type' => 'integer' } }, 'maxProperties' => 0 },
        'items' => { 'properties' => { 'a' => { 'type' => 'string' } } },
      }
    end

    it 'checks items with the original value' do
      expect(validate([{ 'a' => '1' }, {}])).to eq([{ 'a' => '1' }, {}])
    end
  end

  context 'when an item passes contains' do
    let(:target) { { 'contains' => { 'properties' => { 'a' => { 'type' => 'integer' } } } } }

    it 'keeps the item uncoerced' do
      value = [{ 'a' => '1' }]
      expect(validate(value)).to eq([{ 'a' => '1' }])
      expect(value).to eq([{ 'a' => '1' }])
    end
  end
end

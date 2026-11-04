require_relative '../../spec_helper'

RSpec.describe 'dependentRequired keyword' do
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

  context 'when one property depends on another' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'properties' => { 'credit_card' => { 'type' => 'string' }, 'billing_address' => { 'type' => 'string' } },
          'dependentRequired' => { 'credit_card' => ['billing_address'] },
        },
      }
    end

    it 'rejects a value that has the property but not the one it depends on' do
      expect { validate({ 'credit_card' => 'x' }) }.to raise_error(
        OpenAPIParser::NotExistDependentRequiredKey,
        %r{#/components/schemas/Target missing parameters required by credit_card: billing_address},
      )
    end

    it 'accepts a value that has both properties' do
      value = { 'credit_card' => 'x', 'billing_address' => 'y' }
      expect(validate(value)).to eq value
    end

    it 'accepts a value that has neither property' do
      expect(validate({})).to eq({})
    end

    it 'accepts a value that has only the property depended on' do
      value = { 'billing_address' => 'y' }
      expect(validate(value)).to eq value
    end
  end

  context 'when a property depends on several properties' do
    let(:schemas) { { 'Target' => { 'type' => 'object', 'dependentRequired' => { 'a' => %w[b c d] } } } }

    it 'reports all the missing properties' do
      expect { validate({ 'a' => 1, 'c' => 1 }) }.to raise_error(
        OpenAPIParser::NotExistDependentRequiredKey,
        /missing parameters required by a: b, d/,
      )
    end
  end

  context 'when several properties have dependencies' do
    let(:schemas) { { 'Target' => { 'type' => 'object', 'dependentRequired' => { 'a' => ['b'], 'c' => ['d'] } } } }

    it 'checks each of them' do
      expect { validate({ 'a' => 1, 'b' => 1, 'c' => 1 }) }.to raise_error(
        OpenAPIParser::NotExistDependentRequiredKey,
        /missing parameters required by c: d/,
      )
    end
  end

  context 'when the property has a null value' do
    let(:schemas) { { 'Target' => { 'type' => 'object', 'dependentRequired' => { 'a' => ['b'] } } } }

    it 'treats the property as present' do
      expect { validate({ 'a' => nil }) }.to raise_error(OpenAPIParser::NotExistDependentRequiredKey)
    end

    it 'treats the property depended on as present' do
      value = { 'a' => 1, 'b' => nil }
      expect(validate(value)).to eq value
    end
  end

  context 'when the schema has no type' do
    let(:schemas) { { 'Target' => { 'dependentRequired' => { 'a' => ['b'] } } } }

    it 'checks an object' do
      expect { validate({ 'a' => 1 }) }.to raise_error(OpenAPIParser::NotExistDependentRequiredKey)
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
            { 'type' => 'object', 'dependentRequired' => { 'a' => ['b'] } },
          ],
        },
      }
    end

    it 'checks the keyword' do
      expect { validate({ 'a' => 1 }) }.to raise_error(OpenAPIParser::NotExistDependentRequiredKey)
    end
  end

  context 'when the keyword is in a nested schema' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'properties' => { 'nested' => { 'type' => 'object', 'dependentRequired' => { 'a' => ['b'] } } },
        },
      }
    end

    it 'checks the keyword' do
      expect { validate({ 'nested' => { 'a' => 1 } }) }.to raise_error(
        OpenAPIParser::NotExistDependentRequiredKey,
        %r{#/components/schemas/Target/properties/nested missing parameters required by a: b},
      )
    end
  end

  context 'with a 3.0 document' do
    let(:openapi_version) { '3.0.3' }
    let(:schemas) { { 'Target' => { 'type' => 'object', 'dependentRequired' => { 'a' => ['b'] } } } }

    it 'checks the keyword in the same way' do
      expect { validate({ 'a' => 1 }) }.to raise_error(OpenAPIParser::NotExistDependentRequiredKey)
    end
  end

  context 'when the keyword is not an object' do
    let(:schemas) { { 'Target' => { 'type' => 'object', 'dependentRequired' => ['a'] } } }

    it 'ignores the keyword' do
      value = { 'a' => 1 }
      expect(validate(value)).to eq value
    end
  end

  context 'when a dependency is not an array' do
    let(:schemas) { { 'Target' => { 'type' => 'object', 'dependentRequired' => { 'a' => 'b' } } } }

    it 'ignores the dependency' do
      value = { 'a' => 1 }
      expect(validate(value)).to eq value
    end
  end
end

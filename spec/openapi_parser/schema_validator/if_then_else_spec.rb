require_relative '../../spec_helper'

RSpec.describe 'if, then and else keywords' do
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

  context 'when if, then and else are given' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'if' => { 'properties' => { 'kind' => { 'const' => 'card' } }, 'required' => ['kind'] },
          'then' => { 'required' => ['card_number'] },
          'else' => { 'required' => ['account_number'] },
        },
      }
    end

    it 'checks then for a value that passes if' do
      expect { validate({ 'kind' => 'card', 'account_number' => '1' }) }.to raise_error(
        OpenAPIParser::NotExistRequiredKey,
        /missing required parameters: card_number/,
      )
    end

    it 'accepts a value that passes if and then' do
      value = { 'kind' => 'card', 'card_number' => '1' }
      expect(validate(value)).to eq value
    end

    it 'checks else for a value that fails if' do
      expect { validate({ 'kind' => 'bank', 'card_number' => '1' }) }.to raise_error(
        OpenAPIParser::NotExistRequiredKey,
        /missing required parameters: account_number/,
      )
    end

    it 'accepts a value that fails if and passes else' do
      value = { 'kind' => 'bank', 'account_number' => '1' }
      expect(validate(value)).to eq value
    end
  end

  context 'when if and then are given' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'if' => { 'required' => ['card_number'] },
          'then' => { 'required' => ['expiry'] },
        },
      }
    end

    it 'checks then for a value that passes if' do
      expect { validate({ 'card_number' => '1' }) }.to raise_error(
        OpenAPIParser::NotExistRequiredKey,
        %r{#/components/schemas/Target/then missing required parameters: expiry},
      )
    end

    it 'accepts a value that fails if' do
      value = { 'account_number' => '1' }
      expect(validate(value)).to eq value
    end
  end

  context 'when if and else are given' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'if' => { 'required' => ['card_number'] },
          'else' => { 'required' => ['account_number'] },
        },
      }
    end

    it 'checks else for a value that fails if' do
      expect { validate({}) }.to raise_error(
        OpenAPIParser::NotExistRequiredKey,
        %r{#/components/schemas/Target/else missing required parameters: account_number},
      )
    end

    it 'accepts a value that passes if' do
      value = { 'card_number' => '1' }
      expect(validate(value)).to eq value
    end
  end

  context 'when the keywords are next to type' do
    let(:schemas) { { 'Target' => { 'type' => 'integer', 'if' => { 'minimum' => 10 }, 'then' => { 'multipleOf' => 5 } } } }

    it 'checks type' do
      expect { validate('15') }.to raise_error(OpenAPIParser::ValidateError, /expected integer/)
    end

    it 'checks then' do
      expect { validate(12) }.to raise_error(OpenAPIParser::NotMultipleOf)
      expect(validate(15)).to eq 15
      expect(validate(7)).to eq 7
    end
  end

  context 'when the keywords are in a nested schema' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'properties' => {
            'payment' => {
              'type' => 'object',
              'if' => { 'required' => ['card_number'] },
              'then' => { 'required' => ['expiry'] },
            },
          },
        },
      }
    end

    it 'reports the error from the nested schema' do
      expect { validate({ 'payment' => { 'card_number' => '1' } }) }.to raise_error(
        OpenAPIParser::NotExistRequiredKey,
        %r{#/components/schemas/Target/properties/payment/then missing required parameters: expiry},
      )
    end
  end

  context 'when the keywords are next to allOf' do
    let(:schemas) do
      {
        'Target' => {
          'allOf' => [{ 'type' => 'object', 'required' => ['kind'] }],
          'if' => { 'properties' => { 'kind' => { 'const' => 'card' } } },
          'then' => { 'required' => ['card_number'] },
        },
      }
    end

    it 'checks allOf' do
      expect { validate({ 'card_number' => '1' }) }.to raise_error(
        OpenAPIParser::NotExistRequiredKey,
        /missing required parameters: kind/,
      )
    end

    it 'checks then' do
      expect { validate({ 'kind' => 'card' }) }.to raise_error(
        OpenAPIParser::NotExistRequiredKey,
        /missing required parameters: card_number/,
      )
    end
  end

  context 'when if is a $ref' do
    let(:schemas) do
      {
        'Card' => { 'required' => ['card_number'] },
        'Target' => {
          'type' => 'object',
          'if' => { '$ref' => '#/components/schemas/Card' },
          'then' => { 'required' => ['expiry'] },
        },
      }
    end

    it 'checks the referenced schema' do
      expect { validate({ 'card_number' => '1' }) }.to raise_error(
        OpenAPIParser::NotExistRequiredKey,
        /missing required parameters: expiry/,
      )
      value = { 'account_number' => '1' }
      expect(validate(value)).to eq value
    end
  end

  context 'when coerce_value is enabled' do
    let(:coerce_options) { ::OpenAPIParser::SchemaValidator::Options.new(coerce_value: true) }

    context 'with type next to the keywords' do
      let(:schemas) { { 'Target' => { 'type' => 'integer', 'if' => { 'minimum' => 10 }, 'then' => { 'multipleOf' => 5 } } } }

      it 'checks if with the value coerced by type' do
        expect { validate('12', coerce_options) }.to raise_error(OpenAPIParser::NotMultipleOf)
        expect(validate('15', coerce_options)).to eq 15
      end
    end

    context 'with type only in if' do
      let(:schemas) do
        {
          'Target' => {
            'if' => { 'properties' => { 'a' => { 'type' => 'integer' } } },
            'then' => { 'required' => ['b'] },
          },
        }
      end

      it 'coerces the value while checking if' do
        expect { validate({ 'a' => '1' }, coerce_options) }.to raise_error(
          OpenAPIParser::NotExistRequiredKey,
          /missing required parameters: b/,
        )
      end

      it 'does not pass if without coercion' do
        value = { 'a' => '1' }
        expect(validate(value)).to eq value
      end

      it 'keeps the value coerced by if in the Hash' do
        value = { 'a' => '1' }
        expect { validate(value, coerce_options) }.to raise_error(OpenAPIParser::NotExistRequiredKey)
        expect(value).to eq({ 'a' => 1 })
      end
    end

    context 'with type only in if for a value that is not a Hash' do
      let(:schemas) { { 'Target' => { 'if' => { 'type' => 'integer' }, 'then' => { 'minimum' => 10 } } } }

      it 'checks then with the value coerced by if' do
        expect { validate('5', coerce_options) }.to raise_error(OpenAPIParser::LessThanMinimum)
        expect(validate('15', coerce_options)).to eq 15
      end
    end

    context 'with a format that if coerces into another class' do
      let(:date_options) { ::OpenAPIParser::SchemaValidator::Options.new(coerce_value: true, date_coerce_class: Date) }
      let(:schemas) do
        {
          'Target' => {
            'if' => { 'type' => 'string', 'format' => 'date' },
            'then' => { 'type' => 'string', 'pattern' => '^2020-' },
          },
        }
      end

      it 'checks then with the original string' do
        expect(validate('2020-01-01', date_options)).to eq '2020-01-01'
        expect { validate('2021-01-01', date_options) }.to raise_error(OpenAPIParser::InvalidPattern)
      end
    end
  end

  context 'with a 3.0 document' do
    let(:openapi_version) { '3.0.3' }
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'if' => { 'required' => ['card_number'] },
          'then' => { 'required' => ['expiry'] },
          'else' => { 'required' => ['account_number'] },
        },
      }
    end

    it 'checks the keywords in the same way' do
      expect { validate({ 'card_number' => '1' }) }.to raise_error(
        OpenAPIParser::NotExistRequiredKey,
        /missing required parameters: expiry/,
      )
      expect { validate({}) }.to raise_error(
        OpenAPIParser::NotExistRequiredKey,
        /missing required parameters: account_number/,
      )
    end
  end

  context 'when if is a boolean schema' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'integer',
          'allOf' => [
            { 'if' => true, 'then' => { 'minimum' => 10 }, 'else' => { 'maximum' => 0 } },
            { 'if' => false, 'then' => { 'minimum' => 10 }, 'else' => { 'maximum' => 20 } },
          ],
        },
      }
    end

    it 'always checks then for true' do
      expect { validate(5) }.to raise_error(OpenAPIParser::LessThanMinimum, %r{#/components/schemas/Target/allOf/0/then})
    end

    it 'always checks else for false' do
      expect { validate(25) }.to raise_error(OpenAPIParser::MoreThanMaximum, %r{#/components/schemas/Target/allOf/1/else})
      expect(validate(15)).to eq 15
    end
  end

  context 'when then or else is a boolean schema' do
    let(:schemas) { { 'Target' => { 'if' => { 'type' => 'string' }, 'then' => false, 'else' => false } } }

    it 'rejects any value with false' do
      expect { validate('a') }.to raise_error(OpenAPIParser::FalseSchemaError, %r{#/components/schemas/Target/then})
      expect { validate(1) }.to raise_error(OpenAPIParser::FalseSchemaError, %r{#/components/schemas/Target/else})
    end
  end

  context 'when only if is given' do
    let(:schemas) { { 'Target' => { 'if' => { 'type' => 'string' } } } }

    it 'accepts a value that fails if' do
      expect(validate(1)).to eq 1
    end
  end

  context 'when then is given without if' do
    let(:schemas) { { 'Target' => { 'type' => 'string', 'then' => false } } }

    it 'ignores then' do
      expect(validate('a')).to eq 'a'
    end
  end

  context 'when else is given without if' do
    let(:schemas) { { 'Target' => { 'type' => 'string', 'else' => false } } }

    it 'ignores else' do
      expect(validate('a')).to eq 'a'
    end
  end
end

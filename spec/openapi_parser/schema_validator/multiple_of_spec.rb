require_relative '../../spec_helper'

RSpec.describe 'multipleOf keyword' do
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

  context 'when multipleOf is set on an integer' do
    let(:schemas) { { 'Target' => { 'type' => 'integer', 'multipleOf' => 2 } } }

    it 'rejects a value that is not a multiple' do
      expect { validate(3) }.to raise_error(OpenAPIParser::NotMultipleOf, %r{3 isn't a multiple of 2 in #/components/schemas/Target})
    end

    it 'accepts a multiple' do
      expect(validate(4)).to eq 4
    end
  end

  context 'when multipleOf is a decimal on a number' do
    let(:schemas) { { 'Target' => { 'type' => 'number', 'multipleOf' => 0.01 } } }

    it 'accepts a multiple that a binary float cannot divide exactly' do
      expect(validate(19.99)).to eq 19.99
    end

    it 'rejects a value that is not a multiple' do
      expect { validate(1.005) }.to raise_error(OpenAPIParser::NotMultipleOf, /1.005 isn't a multiple of 0.01/)
    end
  end

  context 'when multipleOf is a power-of-two fraction on a number' do
    let(:schemas) { { 'Target' => { 'type' => 'number', 'multipleOf' => 0.5 } } }

    it 'accepts a multiple' do
      expect(validate(1.5)).to eq 1.5
    end

    it 'rejects a value that is not a multiple' do
      expect { validate(1.25) }.to raise_error(OpenAPIParser::NotMultipleOf)
    end
  end

  context 'when multipleOf is an integer on a number' do
    let(:schemas) { { 'Target' => { 'type' => 'number', 'multipleOf' => 2 } } }

    it 'rejects an integer that is not a multiple' do
      expect { validate(3) }.to raise_error(OpenAPIParser::NotMultipleOf)
    end

    it 'accepts a float that is a multiple' do
      expect(validate(4.0)).to eq 4.0
    end
  end

  context 'when the schema has no type' do
    let(:schemas) { { 'Target' => { 'multipleOf' => 3 } } }

    it 'rejects a number that is not a multiple' do
      expect { validate(10) }.to raise_error(OpenAPIParser::NotMultipleOf)
    end

    it 'accepts a multiple' do
      expect(validate(9)).to eq 9
    end

    it 'ignores a string' do
      expect(validate('10')).to eq '10'
    end
  end

  context 'when the document is OpenAPI 3.0' do
    let(:openapi_version) { '3.0.3' }
    let(:schemas) { { 'Target' => { 'type' => 'integer', 'multipleOf' => 2 } } }

    it 'rejects a value that is not a multiple' do
      expect { validate(3) }.to raise_error(OpenAPIParser::NotMultipleOf)
    end
  end

  context 'when coerce_value is on' do
    let(:options) { ::OpenAPIParser::SchemaValidator::Options.new(coerce_value: true) }
    let(:schemas) { { 'Target' => { 'type' => 'integer', 'multipleOf' => 2 } } }

    it 'rejects a string that becomes a value that is not a multiple' do
      expect { validate('3') }.to raise_error(OpenAPIParser::NotMultipleOf)
    end

    it 'accepts a string that becomes a multiple' do
      expect(validate('4')).to eq 4
    end
  end

  context 'when the value is too large to divide as a float' do
    let(:schemas) { { 'Target' => { 'type' => 'number', 'multipleOf' => 0.5 } } }

    it 'accepts an integer-valued float with a fractional multipleOf' do
      expect(validate(1e308)).to eq 1e308
    end
  end

  # multipleOf MUST be a number strictly greater than 0. An invalid one was
  # ignored before this keyword was validated, so it stays ignored.
  context 'when multipleOf is not a positive number' do
    let(:schemas) do
      {
        'String' => { 'type' => 'number', 'multipleOf' => '0.1' },
        'Zero' => { 'type' => 'number', 'multipleOf' => 0 },
        'Negative' => { 'type' => 'number', 'multipleOf' => -2 },
      }
    end

    it 'ignores a string' do
      expect(OpenAPIParser::SchemaValidator.validate(1.5, root.components.schemas['String'], options)).to eq 1.5
    end

    it 'ignores zero' do
      expect(OpenAPIParser::SchemaValidator.validate(1.5, root.components.schemas['Zero'], options)).to eq 1.5
    end

    it 'ignores a negative number' do
      expect(OpenAPIParser::SchemaValidator.validate(1.5, root.components.schemas['Negative'], options)).to eq 1.5
    end
  end
end

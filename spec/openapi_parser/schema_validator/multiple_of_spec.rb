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
    it 'accepts a multiple'
    it 'rejects a value that is not a multiple'
  end

  context 'when multipleOf is an integer on a number' do
    it 'rejects an integer that is not a multiple'
    it 'accepts a float that is a multiple'
  end

  context 'when the schema has no type' do
    it 'rejects a number that is not a multiple'
    it 'accepts a multiple'
    it 'ignores a string'
  end

  context 'when the document is OpenAPI 3.0' do
    it 'rejects a value that is not a multiple'
  end

  context 'when coerce_value is on' do
    it 'rejects a string that becomes a value that is not a multiple'
    it 'accepts a string that becomes a multiple'
  end

  context 'when the value is too large to divide as a float' do
    it 'accepts an integer-valued float with a fractional multipleOf'
  end
end

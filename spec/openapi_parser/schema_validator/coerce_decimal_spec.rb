require_relative '../../spec_helper'

# With coerce_value, a string is read as a decimal number.
# Ruby's Integer() and Float() also read base prefixes such as 0x,
# and Integer() reads a leading zero as octal, so "010" became 8.
RSpec.describe 'coerce_value reads numbers as decimal' do
  let(:options) { ::OpenAPIParser::SchemaValidator::Options.new(coerce_value: true) }
  let(:root) do
    raw = {
      'openapi' => '3.1.0',
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => { 'Target' => { 'type' => type } } },
    }
    OpenAPIParser.parse(raw, strict_reference_validation: true)
  end
  let(:schema) { root.components.schemas['Target'] }

  def validate(value)
    OpenAPIParser::SchemaValidator.validate(value, schema, options)
  end

  describe 'type: integer' do
    let(:type) { 'integer' }

    context 'when the value has only digits' do
      it 'returns the Integer' do
        expect(validate('10')).to eq 10
      end
    end

    context 'when the value has a leading zero' do
      it 'reads it as decimal, not octal' do
        expect(validate('010')).to eq 10
        expect(validate('08')).to eq 8
      end
    end

    context 'when the value has a base prefix' do
      it 'rejects the value' do
        %w[0x10 0b10 0o10].each do |value|
          expect { validate(value) }.to raise_error(OpenAPIParser::ValidateError, /expected integer, but received String: "#{value}"/)
        end
      end
    end
    context 'when the value has a sign, an underscore or spaces around it'
    context 'when the value is larger than 2**53'
  end

  describe 'type: number' do
    let(:type) { 'number' }

    context 'when the value is a decimal number'
    context 'when the value has a leading zero'
    context 'when the value is hexadecimal'
    context 'when the value has a binary or octal prefix'
  end
end

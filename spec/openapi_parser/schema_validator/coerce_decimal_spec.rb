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

    context 'when the value has only digits'
    context 'when the value has a leading zero'
    context 'when the value has a base prefix'
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

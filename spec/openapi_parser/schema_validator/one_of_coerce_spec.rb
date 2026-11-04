require_relative '../../spec_helper'

RSpec.describe 'oneOf with coerce_value' do
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
  let(:integer) { { 'type' => 'integer' } }
  let(:string) { { 'type' => 'string' } }

  def validate(value, validate_options = options)
    OpenAPIParser::SchemaValidator.validate(value, schema, validate_options)
  end

  context 'when a String can also be coerced to another member' do
    let(:target) { { 'oneOf' => [integer, string] } }

    it 'accepts the String as it is' do
      expect(validate('1')).to eq '1'
    end

    context 'with the members in the other order' do
      let(:target) { { 'oneOf' => [string, integer] } }

      it 'does not depend on the order of the members' do
        expect(validate('1')).to eq '1'
      end
    end

    it 'keeps the String that would change if coerced' do
      expect(validate('010')).to eq '010'
    end
  end

  context 'when only a coerced value matches' do
    it 'returns the coerced value'
    it 'rejects a value that matches no member'
  end

  context 'when the value is not a String' do
    it 'accepts the value'
  end

  context 'when several members match the value as it is' do
    it 'rejects the value'
  end

  context 'when several members match only after coercion' do
    it 'rejects the value'
  end

  context 'when the members are objects' do
    it 'keeps the property that matches as it is'
    it 'does not depend on the order of the members'
    it 'coerces the property that matches only after coercion'
  end

  context 'when the matched member coerces to another class' do
    it 'returns the coerced value'
  end

  context 'when the value is not a JSON value' do
    it 'accepts a file object for format: binary'
  end

  context 'without coerce_value' do
    it 'accepts the String as it is'
  end
end

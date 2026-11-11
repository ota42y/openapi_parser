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
    let(:target) { { 'oneOf' => [integer, { 'type' => 'boolean' }] } }

    it 'returns the coerced value' do
      expect(validate('3')).to eq 3
      expect(validate('true')).to eq true
    end

    it 'rejects a value that matches no member' do
      expect { validate('x') }.to raise_error(OpenAPIParser::NotOneOf)
    end
  end

  context 'when the value is not a String' do
    let(:target) { { 'oneOf' => [integer, string] } }

    it 'accepts the value' do
      expect(validate(1)).to eq 1
    end
  end

  context 'when several members match the value as it is' do
    let(:target) { { 'oneOf' => [string, { 'type' => 'string', 'maxLength' => 3 }] } }

    it 'rejects the value' do
      expect { validate('abc') }.to raise_error(OpenAPIParser::NotOneOf)
    end
  end

  context 'when several members match only after coercion' do
    let(:target) { { 'oneOf' => [integer, { 'type' => 'number' }] } }

    it 'rejects the value' do
      expect { validate('1') }.to raise_error(OpenAPIParser::NotOneOf)
    end
  end

  context 'when the members are objects' do
    let(:integer_object) { { 'type' => 'object', 'properties' => { 'n' => integer } } }
    let(:string_object) { { 'type' => 'object', 'properties' => { 'n' => string } } }
    let(:target) { { 'oneOf' => [integer_object, string_object] } }

    it 'keeps the property that matches as it is' do
      expect(validate({ 'n' => '1' })).to eq({ 'n' => '1' })
    end

    context 'with the members in the other order' do
      let(:target) { { 'oneOf' => [string_object, integer_object] } }

      it 'does not depend on the order of the members' do
        expect(validate({ 'n' => '1' })).to eq({ 'n' => '1' })
      end
    end

    context 'when only one member matches after coercion' do
      let(:target) { { 'oneOf' => [integer_object, { 'type' => 'object', 'properties' => { 'n' => { 'type' => 'boolean' } } }] } }

      it 'coerces the property that matches only after coercion' do
        expect(validate({ 'n' => '1' })).to eq({ 'n' => 1 })
      end
    end
  end

  context 'when the matched member coerces to another class' do
    let(:options) { ::OpenAPIParser::SchemaValidator::Options.new(coerce_value: true, datetime_coerce_class: DateTime) }
    let(:target) { { 'oneOf' => [{ 'type' => 'string', 'format' => 'date-time' }, integer] } }

    it 'returns the coerced value' do
      expect(validate('2026-11-05T00:00:00Z')).to be_a(DateTime)
    end
  end

  context 'when the value is not a JSON value' do
    let(:target) { { 'oneOf' => [{ 'type' => 'string', 'format' => 'binary' }, integer] } }

    it 'accepts a file object for format: binary' do
      file = File.open(__FILE__)
      expect(validate(file)).to be file
    ensure
      file.close
    end
  end

  context 'without coerce_value' do
    let(:target) { { 'oneOf' => [integer, string] } }

    it 'accepts the String as it is' do
      expect(validate('1', ::OpenAPIParser::SchemaValidator::Options.new)).to eq '1'
    end
  end
end

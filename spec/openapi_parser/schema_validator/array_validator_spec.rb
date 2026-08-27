require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::SchemaValidator::ArrayValidator do
  let(:replace_schema) { {} }
  let(:root) { OpenAPIParser.parse(build_validate_test_schema(replace_schema), config) }
  let(:config) { {} }
  let(:target_schema) do
    root.paths.path['/validate_test'].operation(:post).request_body.content['application/json'].schema
  end
  let(:options) { ::OpenAPIParser::SchemaValidator::Options.new }

  describe 'validate array' do
    subject { OpenAPIParser::SchemaValidator.validate(params, target_schema, options) }

    let(:params) { {} }
    let(:replace_schema) do
      {
        ids: {
          type: 'array',
          items: { 'type': 'integer' },
          maxItems: 2,
          minItems: 1,
          uniqueItems: true
        },
      }
    end

    context 'correct' do
      let(:params) { { 'ids' => [1] } }
      it { expect(subject).to eq({ 'ids' => [1] }) }
    end

    context 'invalid' do
      context 'max items breached' do
        let(:invalid_array) { [1,2,3,4] }
        let(:params) { { 'ids' => invalid_array } }

        it do
          expect { subject }.to raise_error do |e|
            expect(e).to be_kind_of(OpenAPIParser::MoreThanMaxItems)
            expect(e.message).to end_with("#{invalid_array} contains more than max items")
          end
        end
      end

      context 'min items breached' do
        let(:invalid_array) { [] }
        let(:params) { { 'ids' => invalid_array } }

        it do
          expect { subject }.to raise_error do |e|
            expect(e).to be_kind_of(OpenAPIParser::LessThanMinItems)
            expect(e.message).to end_with("#{invalid_array} contains fewer than min items")
          end
        end
      end

      context 'unique items breached' do
        let(:invalid_array) { [1, 1] }
        let(:params) { { 'ids' => invalid_array } }

        it do
          expect { subject }.to raise_error do |e|
            expect(e).to be_kind_of(OpenAPIParser::NotUniqueItems)
            expect(e.message).to end_with("#{invalid_array} contains duplicate items")
          end
        end
      end
    end
  end

  describe 'prefixItems tuple validation (3.1)' do
    let(:tuple_schema) do
      raw = {
        'openapi' => '3.1.0',
        'info' => { 'title' => 'test', 'version' => '1.0' },
        'paths' => {},
        'components' => {
          'schemas' => {
            'Tuple' => {
              'type' => 'array',
              'prefixItems' => [
                { 'type' => 'string' },
                { 'type' => 'integer' },
              ],
              'items' => { 'type' => 'boolean' },
            },
          },
        },
      }
      OpenAPIParser.parse(raw, strict_reference_validation: false).components.schemas['Tuple']
    end

    context 'when the array obeys prefixItems exactly' do
      it 'passes validation' do
        expect(OpenAPIParser::SchemaValidator.validate(['a', 1], tuple_schema, options)).to eq(['a', 1])
      end
    end

    context 'when an element fails its prefixItems schema' do
      it 'raises a validation error' do
        expect do
          OpenAPIParser::SchemaValidator.validate(['a', 'not_an_integer'], tuple_schema, options)
        end.to raise_error(OpenAPIParser::ValidateError)
      end
    end

    context 'when extra elements are validated against items' do
      it 'passes when extras conform to items' do
        expect(OpenAPIParser::SchemaValidator.validate(['a', 1, true, false], tuple_schema, options)).to eq(['a', 1, true, false])
      end
    end

    context 'when extra elements violate items' do
      it 'raises a validation error' do
        expect do
          OpenAPIParser::SchemaValidator.validate(['a', 1, 'not_boolean'], tuple_schema, options)
        end.to raise_error(OpenAPIParser::ValidateError)
      end
    end
  end
end

require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::SchemaValidator::Base do
  describe '#coerce_and_validate(_value, _schema)' do
    subject { OpenAPIParser::SchemaValidator::Base.new(nil, nil).coerce_and_validate(nil, nil) }

    it { expect { subject }.to raise_error(StandardError).with_message('need implement') }
  end

  describe 'discriminator schema selection' do
    subject { OpenAPIParser::SchemaValidator.validate(params, root.components.schemas['Pet'], options) }

    let(:options) { OpenAPIParser::SchemaValidator::Options.new }
    let(:params) { { 'petType' => 'Cat', 'name' => 'Misty' } }
    let(:discriminator) { { 'propertyName' => 'petType' } }
    let(:candidates) { [{ '$ref' => '#/components/schemas/Cat' }] }
    let(:root) do
      OpenAPIParser.parse({
        'openapi' => '3.0.3',
        'info' => { 'title' => 'test', 'version' => '1.0' },
        'paths' => {},
        'components' => {
          'schemas' => {
            'Pet' => { combination => candidates, 'discriminator' => discriminator },
            'Cat' => {
              'type' => 'object',
              'required' => ['name'],
              'properties' => { 'name' => { 'type' => 'string' } },
              'additionalProperties' => false,
            },
            'CatAlias' => { '$ref' => '#/components/schemas/Cat' },
            'Admin' => { 'type' => 'object', 'additionalProperties' => true },
            'Loose' => { 'type' => 'object', 'properties' => { 'any' => {} } },
          },
        },
      }, strict_reference_validation: true)
    end

    where(:combination) { ['oneOf', 'anyOf'] }

    with_them do
      it 'accepts a listed schema by its implicit name' do
        expect(subject).to eq(params)
      end

      it 'validates the selected schema' do
        params['name'] = 1
        expect { subject }.to raise_error(OpenAPIParser::ValidateError)
      end

      it 'rejects an unlisted permissive component' do
        params.replace('petType' => 'Admin', 'arbitrary' => true)
        expect { subject }.to raise_error(OpenAPIParser::NotExistDiscriminatorMappedSchema)
      end

      it 'rejects a nested schema path as an implicit name' do
        params.replace('petType' => 'Loose/properties/any', 'arbitrary' => true)
        expect { subject }.to raise_error(OpenAPIParser::NotExistDiscriminatorMappedSchema)
      end

      it 'does not URI-decode implicit names' do
        params['petType'] = 'C%61t'
        expect { subject }.to raise_error(OpenAPIParser::NotExistDiscriminatorMappedSchema)
      end

      context 'with a nested schema listed as a candidate' do
        let(:candidates) { [{ '$ref' => '#/components/schemas/Loose/properties/any' }] }
        let(:params) { { 'petType' => 'Loose/properties/any', 'arbitrary' => true } }

        it 'still requires a component name for implicit mapping' do
          expect { subject }.to raise_error(OpenAPIParser::NotExistDiscriminatorMappedSchema)
        end
      end

      context 'with a component alias' do
        let(:candidates) { [{ '$ref' => '#/components/schemas/CatAlias' }] }
        let(:params) { { 'petType' => 'CatAlias', 'name' => 'Misty' } }

        it 'accepts the referenced candidate' do
          expect(subject).to eq(params)
        end
      end

      context 'with an explicit mapping' do
        let(:discriminator) { { 'propertyName' => 'petType', 'mapping' => { 'kitten' => '#/components/schemas/Cat' } } }

        it 'accepts the explicitly mapped schema' do
          params['petType'] = 'kitten'
          expect(subject).to eq(params)
        end

        it 'accepts a listed implicit name absent from the mapping' do
          expect(subject).to eq(params)
        end

        it 'rejects an unlisted implicit name absent from the mapping' do
          params.replace('petType' => 'Admin', 'arbitrary' => true)
          expect { subject }.to raise_error(OpenAPIParser::NotExistDiscriminatorMappedSchema)
        end
      end
    end
  end
end

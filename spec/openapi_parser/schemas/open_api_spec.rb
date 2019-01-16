require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::OpenAPI do
  subject { OpenAPIParser.parse(petstore_schema, {}) }

  describe 'init' do
    it 'correct init' do
      expect(subject).not_to be nil
      expect(subject.root.object_id).to eq subject.object_id
    end
  end

  describe '#openapi' do
    it { expect(subject.openapi).to eq '3.0.0' }
  end

  describe '#paths' do
    it { expect(subject.paths).not_to eq nil }
  end

  describe '#components' do
    it { expect(subject.components).not_to eq nil }
  end

  describe 'valid?' do
    let(:schema) { petstore_schema }
    let(:root) { OpenAPIParser.parse(schema, {}) }
    let(:is_valid) { root.valid_definition? }

    it do
      expect(root.openapi_definition_errors.empty?).to eq true
      expect(is_valid).to eq true
    end

    context 'not exist openapi' do
      let(:schema) do
        s = petstore_schema
        s.delete 'openapi'
        s
      end

      it do
        expect(is_valid) .to eq false
        expect { raise root.openapi_definition_errors.first }.to raise_error(OpenAPIParser::InvalidDefinitionError, /openapi/)
      end
    end

    context 'not exist paths' do
      let(:schema) do
        s = petstore_schema
        s.delete 'paths'
        s
      end

      it do
        expect(is_valid) .to eq false
        expect { raise root.openapi_definition_errors.first }.to raise_error(OpenAPIParser::InvalidDefinitionError, /paths/)
      end
    end
  end
end

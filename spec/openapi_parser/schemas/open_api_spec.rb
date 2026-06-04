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

  describe '#openapi_version' do
    context 'with a typical 3.0.x version like "3.0.0"' do
      it 'returns :v3_0'
    end

    context 'with a typical 3.1.x version like "3.1.0"' do
      it 'returns :v3_1'
    end

    context 'with a minor-only version "3.0"' do
      it 'returns :v3_0'
    end

    context 'with a minor-only version "3.1"' do
      it 'returns :v3_1'
    end

    context 'with a prerelease tag like "3.0.0-rc1"' do
      it 'returns :v3_0 by prefix match'
    end

    context 'with an unknown major version like "4.0.0"' do
      it 'returns :unknown'
    end

    context 'when the openapi field is missing' do
      it 'returns :unknown'
    end

    context 'with a non-string openapi field' do
      it 'returns :unknown'
    end
  end
end

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
    def parse_with_openapi_field(value, present: true)
      schema = { 'info' => { 'title' => 'test', 'version' => '1.0' }, 'paths' => {} }
      schema['openapi'] = value if present
      OpenAPIParser.parse(schema, strict_reference_validation: false)
    end

    context 'with a typical 3.0.x version like "3.0.0"' do
      it 'returns Gem::Version 3.0.0'
    end

    context 'with a typical 3.1.x version like "3.1.0"' do
      it 'returns Gem::Version 3.1.0'
    end

    context 'with a 3.2.x version like "3.2.0"' do
      it 'returns Gem::Version 3.2.0'
    end

    context 'with a minor-only version "3.1"' do
      it 'returns a version equal to 3.1.0'
    end

    context 'with a prerelease tag like "3.1.0-rc1"' do
      it 'returns the release version 3.1.0'
    end

    context 'with a major version beyond 3 like "4.0.0"' do
      it 'returns Gem::Version 4.0.0 without special-casing it'
    end

    context 'when the openapi field is missing' do
      it 'returns nil'
    end

    context 'with a non-string openapi field' do
      it 'returns nil'
    end

    context 'with a string that is not a version like "three"' do
      it 'returns nil'
    end

    context 'with a major-only version "3"' do
      it 'returns nil (OpenAPI versions are at least major.minor)'
    end
  end
end

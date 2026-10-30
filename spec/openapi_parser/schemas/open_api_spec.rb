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
      it 'returns Gem::Version 3.0.0' do
        expect(parse_with_openapi_field('3.0.0').openapi_version).to eq Gem::Version.new('3.0.0')
      end
    end

    context 'with a typical 3.1.x version like "3.1.0"' do
      it 'returns Gem::Version 3.1.0' do
        expect(parse_with_openapi_field('3.1.0').openapi_version).to eq Gem::Version.new('3.1.0')
      end
    end

    context 'with a 3.2.x version like "3.2.0"' do
      it 'returns Gem::Version 3.2.0' do
        expect(parse_with_openapi_field('3.2.0').openapi_version).to eq Gem::Version.new('3.2.0')
      end
    end

    context 'with a minor-only version "3.1"' do
      it 'returns a version equal to 3.1.0' do
        expect(parse_with_openapi_field('3.1').openapi_version).to eq Gem::Version.new('3.1.0')
      end
    end

    context 'with a prerelease tag like "3.1.0-rc1"' do
      it 'returns the release version 3.1.0' do
        expect(parse_with_openapi_field('3.1.0-rc1').openapi_version).to eq Gem::Version.new('3.1.0')
      end
    end

    context 'with a major version beyond 3 like "4.0.0"' do
      it 'returns Gem::Version 4.0.0 without special-casing it' do
        expect(parse_with_openapi_field('4.0.0').openapi_version).to eq Gem::Version.new('4.0.0')
      end
    end

    context 'when the openapi field is missing' do
      it 'returns nil' do
        expect(parse_with_openapi_field(nil, present: false).openapi_version).to be_nil
      end
    end

    context 'with a non-string openapi field' do
      it 'returns nil' do
        expect(parse_with_openapi_field(31).openapi_version).to be_nil
      end
    end

    context 'with a string that is not a version like "three"' do
      it 'returns nil' do
        expect(parse_with_openapi_field('three').openapi_version).to be_nil
      end
    end

    context 'with a major-only version "3"' do
      it 'returns nil (OpenAPI versions are at least major.minor)' do
        expect(parse_with_openapi_field('3').openapi_version).to be_nil
      end
    end
  end

  describe '#use_3_2_features?' do
    def parse_with_openapi_field(value, config = {}, present: true)
      schema = { 'info' => { 'title' => 'test', 'version' => '1.0' }, 'paths' => {} }
      schema['openapi'] = value if present
      OpenAPIParser.parse(schema, { strict_reference_validation: false }.merge(config))
    end

    it 'is true for a 3.2 document' do
      expect(parse_with_openapi_field('3.2.0').use_3_2_features?).to eq true
    end

    it 'is false for 3.0 and 3.1 documents' do
      expect(parse_with_openapi_field('3.0.3').use_3_2_features?).to eq false
      expect(parse_with_openapi_field('3.1.0').use_3_2_features?).to eq false
    end

    it 'is false when the version is missing or malformed' do
      expect(parse_with_openapi_field(nil, present: false).use_3_2_features?).to eq false
      expect(parse_with_openapi_field('not-a-version').use_3_2_features?).to eq false
    end

    it 'is true for any document with allow_3_2_features' do
      expect(parse_with_openapi_field('3.0.3', { allow_3_2_features: true }).use_3_2_features?).to eq true
    end
  end
end

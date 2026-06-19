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
      it 'returns :v3_0' do
        expect(parse_with_openapi_field('3.0.0').openapi_version).to eq :v3_0
      end
    end

    context 'with a typical 3.1.x version like "3.1.0"' do
      it 'returns :v3_1' do
        expect(parse_with_openapi_field('3.1.0').openapi_version).to eq :v3_1
      end
    end

    context 'with a minor-only version "3.0"' do
      it 'returns :v3_0' do
        expect(parse_with_openapi_field('3.0').openapi_version).to eq :v3_0
      end
    end

    context 'with a minor-only version "3.1"' do
      it 'returns :v3_1' do
        expect(parse_with_openapi_field('3.1').openapi_version).to eq :v3_1
      end
    end

    context 'with a prerelease tag like "3.0.0-rc1"' do
      it 'returns :v3_0 by prefix match' do
        expect(parse_with_openapi_field('3.0.0-rc1').openapi_version).to eq :v3_0
      end
    end

    context 'with an unknown major version like "4.0.0"' do
      it 'returns :unknown' do
        expect(parse_with_openapi_field('4.0.0').openapi_version).to eq :unknown
      end
    end

    context 'when the openapi field is missing' do
      it 'returns :unknown' do
        expect(parse_with_openapi_field(nil, present: false).openapi_version).to eq :unknown
      end
    end

    context 'with a non-string openapi field' do
      it 'returns :unknown' do
        expect(parse_with_openapi_field(31).openapi_version).to eq :unknown
      end
    end
  end
end

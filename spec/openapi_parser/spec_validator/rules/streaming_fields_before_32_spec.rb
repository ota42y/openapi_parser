require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::StreamingFieldsBefore32' do
  def base_doc(openapi_version_string, media_type)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {
        '/events' => {
          'get' => {
            'responses' => {
              '200' => {
                'description' => 'OK',
                'content' => { 'text/event-stream' => media_type },
              },
            },
          },
        },
      },
    }
  end

  def doc_with_streaming_fields(openapi_version_string)
    media_type = {
      'itemSchema' => { 'type' => 'object' },
      'itemEncoding' => { 'event' => { 'contentType' => 'text/plain' } },
      'prefixEncoding' => [{ 'contentType' => 'application/json' }],
    }
    OpenAPIParser.parse(base_doc(openapi_version_string, media_type), strict_reference_validation: false)
  end

  def doc_without_streaming_fields(openapi_version_string)
    media_type = { 'schema' => { 'type' => 'string' } }
    OpenAPIParser.parse(base_doc(openapi_version_string, media_type), strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::StreamingFieldsBefore32.new(root.openapi_version).check(root)
  end

  context 'with a 3.2 document using the streaming fields' do
    it 'reports no violation' do
      root = doc_with_streaming_fields('3.2.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.2 document without the streaming fields' do
    it 'reports no violation' do
      root = doc_without_streaming_fields('3.2.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document using the streaming fields' do
    it 'reports one violation per offending field pointing at the media type' do
      root = doc_with_streaming_fields('3.1.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 3
      base = '#/paths/~1events/get/responses/200/content/text~1event-stream'
      expect(violations.map(&:path)).to match_array [
        "#{base}/itemSchema",
        "#{base}/itemEncoding",
        "#{base}/prefixEncoding",
      ]
      expect(violations.first.rule_name).to eq :streaming_fields_before32
    end
  end

  context 'with a 3.1 document without the streaming fields' do
    it 'reports no violation' do
      root = doc_without_streaming_fields('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using the streaming fields' do
    it 'reports violations' do
      root = doc_with_streaming_fields('3.0.0')
      expect(run_rule_for(root).size).to eq 3
    end
  end

  context 'with a 3.1 document nesting encodings inside an Encoding Object' do
    it 'reports each nested field' do
      media_type = {
        'schema' => { 'type' => 'object' },
        'encoding' => {
          'parts' => {
            'contentType' => 'multipart/mixed',
            'itemEncoding' => { 'contentType' => 'application/json' },
            'prefixEncoding' => [{ 'contentType' => 'text/plain' }],
            'encoding' => { 'meta' => { 'contentType' => 'application/json' } },
          },
          'plain' => { 'contentType' => 'text/plain' },
        },
      }
      root = OpenAPIParser.parse(base_doc('3.1.0', media_type), strict_reference_validation: false)
      expect(run_rule_for(root).map(&:path)).to match_array %w[itemEncoding prefixEncoding encoding].map { |field|
        "#/paths/~1events/get/responses/200/content/text~1event-stream/encoding/parts/#{field}"
      }
    end
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)' do
      root = doc_with_streaming_fields('not-a-version')
      expect(run_rule_for(root)).to eq []
    end
  end
end

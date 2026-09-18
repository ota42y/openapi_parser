require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::MediaType do
  let(:root) { OpenAPIParser.parse(petstore_schema, { expand_reference: false }) }

  describe 'correct init' do
    subject { request_body.content['application/json'] }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/pets'] }
    let(:operation) { path_item.post }
    let(:request_body) { operation.request_body }

    it do
      expect(subject.class).to eq OpenAPIParser::Schemas::MediaType
      expect(subject.object_reference).to eq '#/paths/~1pets/post/requestBody/content/application~1json'
      expect(subject.root.object_id).to be root.object_id

      expect(subject.schema.class).to eq OpenAPIParser::Schemas::Reference
    end
  end

  describe 'itemSchema (OpenAPI 3.2)' do
    let(:root) { OpenAPIParser.parse(load_yaml_file('./spec/data/openapi_3_2/streaming_fields_32.yaml'), {}) }

    it 'is parsed as a Schema' do
      media_type = root.find_object('#/paths/~1events/get/responses/200/content/text~1event-stream')
      expect(media_type.item_schema.class).to eq OpenAPIParser::Schemas::Schema
      expect(media_type.item_schema.type).to eq 'object'
    end
  end
end

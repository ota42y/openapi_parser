require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::PathItem do
  let(:root) { OpenAPIParser.parse(normal_schema, {}) }

  describe '#init' do
    subject { path_item }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/characters'] }

    it do
      expect(subject).not_to be nil
      expect(subject.object_reference).to eq '#/paths/~1characters'
      expect(subject.summary).to eq 'summary_text'
      expect(subject.description).to eq 'desc'
      expect(subject.root.object_id).to be root.object_id
    end
  end

  describe '#parameters' do
    subject { path_item }

    let(:root) { OpenAPIParser.parse(petstore_schema, {}) }
    let(:paths) { root.paths }
    let(:path_item) { paths.path['/animals/{id}'] }

    it do
      expect(subject.parameters.size).to eq 2
      expect(subject.parameters.first.name).to eq 'id'
    end
  end

  describe '#get' do
    subject { path_item.get }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/characters'] }

    it do
      expect(subject).not_to eq nil
      expect(subject.kind_of?(OpenAPIParser::Schemas::Operation)).to eq true
      expect(subject.object_reference).to eq '#/paths/~1characters/get'
    end
  end

  describe '#post' do
    subject { path_item.post }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/characters'] }

    it do
      expect(subject).not_to eq nil
      expect(subject.kind_of?(OpenAPIParser::Schemas::Operation)).to eq true
    end
  end

  describe '#head' do
    subject { path_item.head }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/characters'] }

    it do
      expect(subject).to eq nil # head is null
    end
  end

  describe 'query and additionalOperations (OpenAPI 3.2)' do
    let(:root) { OpenAPIParser.parse(load_yaml_file('./spec/data/openapi_3_2/query_method_32.yaml'), {}) }
    let(:path_item) { root.paths.path['/pets'] }

    it 'parses the query operation and finds it via #operation' do
      expect(path_item.query.class).to eq OpenAPIParser::Schemas::Operation
      expect(path_item.operation(:query)).to eq path_item.query
      expect(path_item.operation('QUERY')).to eq path_item.query
    end

    describe 'additionalOperations' do
      let(:root) { OpenAPIParser.parse(load_yaml_file('./spec/data/openapi_3_2/additional_operations_32.yaml'), {}) }

      it 'parses entries as Operations and finds them via #operation' do
        copy = path_item.operation('COPY')
        expect(copy.class).to eq OpenAPIParser::Schemas::Operation
        expect(path_item.operation(:copy)).to eq copy
        expect(path_item.operation('Copy')).to eq copy
        expect(path_item.operation('LINK')).to eq nil
      end
    end

    it 'returns nil for non-operation path item fields' do
      expect(path_item.operation(:summary)).to eq nil
    end
  end
end

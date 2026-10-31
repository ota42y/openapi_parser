require_relative '../../spec_helper'
require 'tmpdir'

RSpec.describe OpenAPIParser::Findable do
  let(:root) { OpenAPIParser.parse(petstore_schema, {}) }

  describe 'openapi object' do
    subject { root }

    it do
      expect(subject.find_object('#/paths/~1pets/get').object_reference).to eq root.paths.path['/pets'].get.object_reference
      expect(subject.find_object('#/components/requestBodies/test_body').object_reference).to eq root.components.request_bodies['test_body'].object_reference

      expect(subject.instance_variable_get(:@find_object_cache).size).to eq 2
    end
  end

  describe 'schema object' do
    subject { root.paths }

    it do
      expect(subject.find_object('#/paths/~1pets/get').object_reference).to eq root.paths.path['/pets'].get.object_reference
    end
  end

  describe 'JSON Pointer escapes in path references' do
    let(:document) do
      {
        'openapi' => '3.0.3',
        'info' => { 'title' => 'test', 'version' => '1.0' },
        'paths' => {
          '/resource/test' => { 'summary' => 'slash' },
          '/resource~test' => { 'summary' => 'tilde' },
          '/resource~1test' => { 'summary' => 'literal ~1' },
          '/resource~0test' => { 'summary' => 'literal ~0' },
        },
      }
    end

    where(:pointer, :path_name) do
      [
        ['~1resource~1test', '/resource/test'],
        ['~1resource~0test', '/resource~test'],
        ['~1resource~01test', '/resource~1test'],
        ['~1resource~00test', '/resource~0test'],
        ['%7E1resource%7E1test', '/resource/test'],
      ]
    end

    with_them do
      it 'resolves a reference in the same document' do
        document['paths']['/reference'] = { '$ref' => "#/paths/#{pointer}" }
        parsed = OpenAPIParser.parse(document, strict_reference_validation: true)

        expect(parsed.paths.path['/reference']).to equal(parsed.paths.path[path_name])
      end

      it 'resolves a reference in another file' do
        Dir.mktmpdir do |directory|
          File.write(File.join(directory, 'file.yaml'), Psych.dump(document))
          source = document.merge('paths' => { '/reference' => { '$ref' => "file.yaml#/paths/#{pointer}" } })
          source_path = File.join(directory, 'source.yaml')
          File.write(source_path, Psych.dump(source))
          parsed = OpenAPIParser.load(source_path, strict_reference_validation: true)

          expect(parsed.paths.path['/reference'].raw_schema).to eq(document['paths'][path_name])
        end
      end
    end
  end

  describe 'JSON Pointer escapes in property references' do
    let(:properties) do
      {
        'a/b' => { 'type' => 'string' },
        'a~b' => { 'type' => 'integer' },
        'a~1b' => { 'type' => 'boolean' },
        'a~0b' => { 'type' => 'number' },
        'a' => { 'type' => 'object', 'properties' => { 'b' => { 'type' => 'array' } } },
      }
    end
    let(:root) do
      OpenAPIParser.parse({
        'openapi' => '3.0.3',
        'info' => { 'title' => 'test', 'version' => '1.0' },
        'paths' => {},
        'components' => { 'schemas' => { 'Object' => { 'type' => 'object', 'properties' => properties } } },
      }, strict_reference_validation: true)
    end

    where(:pointer, :type) do
      [
        ['a~1b', 'string'],
        ['a~0b', 'integer'],
        ['a~01b', 'boolean'],
        ['a~00b', 'number'],
        ['a/properties/b', 'array'],
      ]
    end

    with_them do
      it 'resolves the correct property without confusing escaped keys or nested objects' do
        properties['reference'] = { '$ref' => "#/components/schemas/Object/properties/#{pointer}" }

        expect(root.components.schemas['Object'].properties['reference'].type).to eq(type)
      end
    end
  end

  describe '$ref into $defs (3.1)' do
    def parse_with_schemas(schemas)
      OpenAPIParser.parse({
        'openapi' => '3.1.0',
        'info' => { 'title' => 'test', 'version' => '1.0' },
        'paths' => {},
        'components' => { 'schemas' => schemas },
      }, strict_reference_validation: true)
    end

    context 'when a $ref points at a $defs entry of a component schema' do
      it 'resolves to the $defs schema' do
        root = parse_with_schemas(
          'Pet' => { 'type' => 'object', '$defs' => { 'Id' => { 'type' => 'integer' } } },
          'PetId' => { '$ref' => '#/components/schemas/Pet/$defs/Id' },
        )

        expect(root.components.schemas['PetId']).to equal(root.components.schemas['Pet'].defs['Id'])
      end
    end

    context 'when a $defs entry refers to another $defs entry' do
      it 'resolves the reference inside $defs'
    end

    context 'when $defs is nested inside a $defs entry' do
      it 'resolves the nested entry'
    end

    context 'when the $defs entry does not exist' do
      it 'raises MissingReferenceError'
    end
  end

  describe 'remote reference' do
    describe 'local file reference' do
      let(:root) { OpenAPIParser.load('spec/data/remote-file-ref.yaml') }
      let(:request_operation) { root.request_operation(:post, '/local_file_reference') }

      it 'validates request body using schema defined in another openapi yaml file' do
        request_operation.validate_request_body('application/json', { 'name' => 'name' })
      end
    end

    describe 'http reference' do
      let(:root) { OpenAPIParser.load('spec/data/remote-http-ref.yaml') }
      let(:request_operation) { root.request_operation(:post, '/http_reference') }

      it 'validates request body using schema defined in openapi yaml file accessed via http' do
        request_operation.validate_request_body('application/json', { 'name' => 'name' })
      end
    end

    describe 'cyclic remote reference' do
      let(:root) { OpenAPIParser.load('spec/data/cyclic-remote-ref1.yaml') }
      let(:request_operation) { root.request_operation(:post, '/cyclic_reference') }

      it 'validates request body using schema defined in another openapi yaml file' do
        request_operation.validate_request_body('application/json', { 'content' => 1 })
      end
    end
  end
end

require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Expandable do
  let(:root) { OpenAPIParser.parse(normal_schema, {}) }

  describe 'expand_reference' do
    subject { root }

    it do
      subject
      expect(subject.find_object('#/paths/~1reference/get/parameters/0').class).to eq OpenAPIParser::Schemas::Parameter
      expect(subject.find_object('#/paths/~1reference/get/responses/default').class).to eq OpenAPIParser::Schemas::Response
      expect(subject.find_object('#/paths/~1reference/post/responses/default').class).to eq OpenAPIParser::Schemas::Response
      path = '#/paths/~1string_params_coercer/post/requestBody/content/application~1json/schema/properties/nested_array'
      expect(subject.find_object(path).class).to eq OpenAPIParser::Schemas::Schema
    end

    context 'undefined spec references' do
      let(:invalid_reference) { '#/paths/~1ref-sample~1broken_reference/get/requestBody' }
      let(:not_configured) { {} }
      let(:raise_on_invalid_reference) { { strict_reference_validation: true } }
      let(:misconfiguration) {
        {
          expand_reference: false,
          strict_reference_validation: true
        }
      }

      it 'raises when configured to do so' do
        raise_message = "'#/components/requestBodies/foobar' was referenced but could not be found"
        expect { OpenAPIParser.parse(broken_reference_schema, raise_on_invalid_reference) }.to(
          raise_error(OpenAPIParser::MissingReferenceError) { |error| expect(error.message).to eq(raise_message) }
        )
      end

      it 'does not raise when not configured, returns nil reference' do
        subject = OpenAPIParser.parse(broken_reference_schema, not_configured)
        expect(subject.find_object(invalid_reference)).to be_nil
      end

      it 'does not raise when configured, but expand_reference is false' do
        subject = OpenAPIParser.parse(broken_reference_schema, misconfiguration)
        expect(subject.find_object(invalid_reference)).to be_nil
      end
    end

    context 'a path that $refs into components.pathItems (OpenAPI 3.1)' do
      it 'resolves the path item instead of raising MissingReferenceError' do
        root = OpenAPIParser.parse(
          load_yaml_file('./spec/data/openapi_3_1/components_path_items.yaml'),
          strict_reference_validation: true,
        )
        expect(root.paths.path['/books'].class).to eq OpenAPIParser::Schemas::PathItem
        expect(root.request_operation(:get, '/books').class).to eq OpenAPIParser::RequestOperation
      end
    end

    context 'content that $refs into components.mediaTypes (OpenAPI 3.2)' do
      let(:root) do
        OpenAPIParser.parse(
          load_yaml_file('./spec/data/openapi_3_2/media_types_32.yaml'),
          strict_reference_validation: true,
        )
      end

      it 'resolves the media type in a request body' do
        media_type = root.request_operation(:post, '/pets').operation_object.request_body.content['application/json']
        expect(media_type.schema.class).to eq OpenAPIParser::Schemas::Schema
      end

      it 'resolves the media type in a response' do
        media_type = root.request_operation(:get, '/pets').operation_object.responses.response['200'].content['application/json']
        expect(media_type.schema.class).to eq OpenAPIParser::Schemas::Schema
      end

      it 'validates a request body against the referenced media type schema' do
        request_operation = root.request_operation(:post, '/pets')
        expect { request_operation.validate_request_body('application/json', { 'id' => 'not-an-integer' }) }
          .to raise_error(OpenAPIParser::ValidateError)
      end
    end

    context 'content $refs outside components.mediaTypes' do
      # POST /pets reuses the media type declared on POST /templates
      def parse_content_ref(version, ref, config = {})
        operation = ->(media_type) { { 'requestBody' => { 'content' => { 'application/json' => media_type } }, 'responses' => { '201' => { 'description' => 'Created' } } } }
        raw = {
          'openapi' => version,
          'info' => { 'title' => 'test', 'version' => '1.0' },
          'paths' => {
            '/templates' => { 'post' => operation.({ 'schema' => { 'type' => 'integer' } }) },
            '/pets' => { 'post' => operation.({ '$ref' => ref }) },
          },
        }
        OpenAPIParser.parse(raw, { strict_reference_validation: false }.merge(config))
      end

      let(:template_ref) { '#/paths/~1templates/post/requestBody/content/application~1json' }

      %w[3.0.3 3.1.0].each do |version|
        context "in a #{version} document" do
          it 'leaves the $ref unresolved and accepts any body, as before 3.2' do
            request_operation = parse_content_ref(version, template_ref).request_operation(:post, '/pets')
            expect(request_operation.operation_object.request_body.content['application/json'].schema).to eq nil
            expect(request_operation.validate_request_body('application/json', { 'id' => 'x' })).to eq({ 'id' => 'x' })
          end

          it 'does not raise for a missing target under strict_reference_validation' do
            expect { parse_content_ref(version, '#/nope', { strict_reference_validation: true }) }.not_to raise_error
          end

          it 'resolves the $ref with allow_3_2_features' do
            request_operation = parse_content_ref(version, template_ref, { allow_3_2_features: true }).request_operation(:post, '/pets')
            expect { request_operation.validate_request_body('application/json', { 'id' => 'x' }) }
              .to raise_error(OpenAPIParser::ValidateError)
          end
        end
      end

      context 'in a 3.2 document' do
        it 'resolves the $ref' do
          request_operation = parse_content_ref('3.2.0', template_ref).request_operation(:post, '/pets')
          expect { request_operation.validate_request_body('application/json', { 'id' => 'x' }) }
            .to raise_error(OpenAPIParser::ValidateError)
        end

        it 'raises for a missing target under strict_reference_validation' do
          expect { parse_content_ref('3.2.0', '#/nope', { strict_reference_validation: true }) }
            .to raise_error(OpenAPIParser::MissingReferenceError)
        end

        it 'falls back to a schemaless media type for a missing target without strict_reference_validation' do
          request_operation = parse_content_ref('3.2.0', '#/nope').request_operation(:post, '/pets')
          expect(request_operation.operation_object.request_body.content['application/json'].class).to eq OpenAPIParser::Schemas::MediaType
          expect(request_operation.validate_request_body('application/json', { 'id' => 'x' })).to eq({ 'id' => 'x' })
        end
      end
    end

    context 'content $refs in a referenced file that declares no version' do
      def load_pets_operation(suffix)
        OpenAPIParser.load("./spec/data/openapi_3_2/media_type_refs_external_#{suffix}.yaml", strict_reference_validation: false)
          .request_operation(:post, '/pets')
      end

      it 'resolves them when the loading document is 3.2' do
        expect { load_pets_operation('32').validate_request_body('application/json', { 'id' => 'x' }) }
          .to raise_error(OpenAPIParser::ValidateError)
      end

      it 'leaves them unresolved when the loading document is 3.0' do
        expect(load_pets_operation('30').validate_request_body('application/json', { 'id' => 'x' })).to eq({ 'id' => 'x' })
      end
    end
  end
end

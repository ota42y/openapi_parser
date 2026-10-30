require_relative '../spec_helper'

RSpec.describe OpenAPIParser::RequestOperation do
  let(:root) { OpenAPIParser.parse(petstore_schema, {}) }
  let(:config) { OpenAPIParser::Config.new({}) }
  let(:path_item_finder) { OpenAPIParser::PathItemFinder.new(root.paths) }

  describe 'find' do
    it 'no path items' do
      ro = OpenAPIParser::RequestOperation.create(:get, '/pets', path_item_finder, config.request_validator_options)
      expect(ro.operation_object.object_reference).to eq '#/paths/~1pets/get'
      expect(ro.http_method).to eq('get')
      expect(ro.path_item.object_id).to eq root.paths.path['/pets'].object_id
    end

    it 'path items' do
      ro = OpenAPIParser::RequestOperation.create(:get, '/pets/1', path_item_finder, config.request_validator_options)
      expect(ro.operation_object.object_reference).to eq '#/paths/~1pets~1{id}/get'
      expect(ro.path_item.object_id).to eq root.paths.path['/pets/{id}'].object_id
    end

    it 'no path' do
      ro = OpenAPIParser::RequestOperation.create(:get, 'no', path_item_finder, config.request_validator_options)
      expect(ro).to eq nil
    end

    it 'no method' do
      ro = OpenAPIParser::RequestOperation.create(:head, '/pets/1', path_item_finder, config.request_validator_options)
      expect(ro).to eq nil
    end
  end

  describe 'OpenAPI#request_operation' do
    it 'no path items' do
      ro = root.request_operation(:get, '/pets')
      expect(ro.operation_object.object_reference).to eq '#/paths/~1pets/get'

      ro = OpenAPIParser::RequestOperation.create(:head, '/pets/1', path_item_finder, config.request_validator_options)
      expect(ro).to eq nil
    end

    # 3.1: a document may have only `webhooks` and no `paths`
    context 'with a document that has webhooks but no paths' do
      let(:root) do
        OpenAPIParser.parse({
          'openapi' => '3.1.0',
          'info' => { 'title' => 'test', 'version' => '1.0' },
          'webhooks' => {
            'newPet' => { 'post' => { 'responses' => { '200' => { 'description' => 'ok' } } } },
          },
        }, {})
      end

      it 'returns nil instead of raising' do
        expect(root.request_operation(:get, '/pets')).to be_nil
      end

      it 'still exposes webhooks' do
        expect(root.webhooks['newPet']).to be_a(OpenAPIParser::Schemas::PathItem)
      end
    end

    context 'with a document that has empty paths' do
      let(:root) do
        OpenAPIParser.parse({
          'openapi' => '3.1.0',
          'info' => { 'title' => 'test', 'version' => '1.0' },
          'paths' => {},
        }, {})
      end

      it 'returns nil' do
        expect(root.request_operation(:get, '/pets')).to be_nil
      end
    end
  end

  describe 'validate_response_body' do
    subject { request_operation.validate_response_body(response_body) }

    let(:root) { OpenAPIParser.parse(normal_schema, init_config) }

    let(:init_config) { {} }

    let(:response_body) do
      OpenAPIParser::RequestOperation::ValidatableResponseBody.new(status_code, data, headers)
    end
    let(:headers) { { 'Content-Type' => content_type } }

    let(:status_code) { 200 }
    let(:http_method) { :post }
    let(:content_type) { 'application/json' }
    let(:request_operation) { root.request_operation(http_method, '/validate') }

    context 'correct' do
      let(:data) { { 'string' => 'Honoka.Kousaka' } }

      it { expect(subject).to eq({ 'string' => 'Honoka.Kousaka' }) }
    end

    context 'no content type' do
      let(:content_type) { nil }
      let(:data) { { 'string' => 1 } }

      it { expect(subject).to eq true }
    end

    context 'with header' do
      let(:root) { OpenAPIParser.parse(petstore_schema, init_config) }

      let(:http_method) { :get }
      let(:request_operation) { root.request_operation(http_method, '/pets') }
      let(:headers_base) { { 'Content-Type' => content_type } }
      let(:data) { [] }

      context 'valid header type' do
        let(:headers) { headers_base.merge('x-next': 'next', 'x-limit' => 1) }

        it { expect(subject).to eq [] }
      end

      context 'invalid header type' do
        let(:headers) { headers_base.merge('x-next': 'next', 'x-limit' => '1') }

        it { expect { subject }.to raise_error(OpenAPIParser::ValidateError) }
      end

      context 'invalid non-nullbale header value' do
        let(:headers) { headers_base.merge('non-nullable-x-limit' => nil) }

        it { expect { subject }.to raise_error(OpenAPIParser::NotNullError) }
      end

      context 'no check option' do
        let(:headers) { headers_base.merge('x-next': 'next', 'x-limit' => '1') }
        let(:init_config) { { validate_header: false } }

        it { expect(subject).to eq [] }
      end
    end

    context 'invalid schema' do
      let(:data) { { 'string' => 1 } }

      it do
        expect { subject }.to raise_error do |e|
          expect(e).to be_kind_of(OpenAPIParser::ValidateError)
          expect(e.message).to end_with("expected string, but received Integer: 1")
        end
      end
    end

    context 'no status code use default' do
      let(:status_code) { 419 }
      let(:data) { { 'integer' => '1' } }

      it do
        expect { subject }.to raise_error do |e|
          expect(e).to be_kind_of(OpenAPIParser::ValidateError)
          expect(e.message).to end_with("expected integer, but received String: \"1\"")
        end
      end
    end

    context 'with option' do
      context 'strict option' do
        let(:http_method) { :put }

        context 'method parameter' do
          subject { request_operation.validate_response_body(response_body, response_validate_options) }

          let(:response_body) do
            OpenAPIParser::RequestOperation::ValidatableResponseBody.new(status_code, data, headers)
          end
          let(:headers) { { 'Content-Type' => content_type } }

          let(:response_validate_options) { OpenAPIParser::SchemaValidator::ResponseValidateOptions.new(strict: true) }
          let(:data) { {} }

          context 'not exist status code' do
            let(:status_code) { 201 }

            it do
              expect { subject }.to raise_error do |e|
                expect(e).to be_kind_of(OpenAPIParser::NotExistStatusCodeDefinition)
                expect(e.message).to end_with("status code definition does not exist")
              end
            end
          end

          context 'not exist content type' do
            let(:content_type) { 'application/xml' }
            let(:data) { '<something></something>' }

            it do
              expect { subject }.to raise_error do |e|
                expect(e).to be_kind_of(OpenAPIParser::NotExistContentTypeDefinition)
                expect(e.message).to end_with("response definition does not exist")
              end
            end
          end

          context 'with nil content type when the response body is blank' do
            let(:status_code) { 204 }
            let(:content_type) { nil }
            let(:data) { '' }
            let(:http_method) { :get }

            it do
              expect { subject }.to_not raise_error
              expect(subject).to eq true
            end
          end
        end

        context 'default parameter' do
          subject { request_operation.validate_response_body(response_body) }

          let(:data) { {} }
          let(:init_config) { { strict_response_validation: true } }

          let(:response_body) do
            OpenAPIParser::RequestOperation::ValidatableResponseBody.new(status_code, data, headers)
          end
          let(:headers) { { 'Content-Type' => content_type } }

          context 'not exist status code' do
            let(:status_code) { 201 }

            it do
              expect { subject }.to raise_error do |e|
                expect(e).to be_kind_of(OpenAPIParser::NotExistStatusCodeDefinition)
                expect(e.message).to end_with("status code definition does not exist")
              end
            end
          end

          context 'not exist content type' do
            let(:content_type) { 'application/xml' }
            let(:data) { '<something></something>' }

            it do
              expect { subject }.to raise_error do |e|
                expect(e).to be_kind_of(OpenAPIParser::NotExistContentTypeDefinition)
                expect(e.message).to end_with("response definition does not exist")
              end
            end
          end
        end
      end
    end
  end
end

RSpec.describe OpenAPIParser::RequestOperation::ValidatableResponseBody do
  describe '#content_type' do
    context 'when key is lowercase' do
      let(:headers) { {"content-type" => "application/json"} }
        it 'finds the key' do
          expect(
            OpenAPIParser::RequestOperation::ValidatableResponseBody.new(nil, nil, headers).content_type
          ).to eq "application/json"
      end
    end
    context 'when key is mixed case' do
      let(:headers) { {"Content-Type" => "application/json"} }
        it 'finds the key' do
          expect(
            OpenAPIParser::RequestOperation::ValidatableResponseBody.new(nil, nil, headers).content_type
          ).to eq "application/json"
      end
    end
  end

  describe 'standard method case' do
    it 'does not find an uppercase method name in a 3.0 document, as before 3.2' do
      root = OpenAPIParser.parse(petstore_schema, {})
      expect(root.request_operation('GET', '/pets')).to eq nil
    end

    it 'finds an uppercase method name in a 3.0 document with allow_3_2_features' do
      root = OpenAPIParser.parse(petstore_schema, { allow_3_2_features: true })
      expect(root.request_operation('GET', '/pets').operation_object).to eq root.request_operation(:get, '/pets').operation_object
    end

    it 'finds an uppercase method name in a 3.2 document' do
      root = OpenAPIParser.parse(petstore_schema.merge('openapi' => '3.2.0'), {})
      expect(root.request_operation('GET', '/pets').operation_object).to eq root.request_operation(:get, '/pets').operation_object
    end
  end

  describe 'OpenAPI 3.2 operations' do
    context 'with a query operation' do
      let(:root) { OpenAPIParser.parse(load_yaml_file('./spec/data/openapi_3_2/query_method_32.yaml'), {}) }

      it 'finds the request operation and validates its body' do
        request_operation = root.request_operation(:query, '/pets')
        expect(request_operation.operation_object.class).to eq OpenAPIParser::Schemas::Operation
        expect(request_operation.validate_request_body('application/json', { 'nameStartsWith' => 'R' })).to eq({ 'nameStartsWith' => 'R' })
      end
    end

    context 'with an additionalOperations method' do
      let(:root) { OpenAPIParser.parse(load_yaml_file('./spec/data/openapi_3_2/additional_operations_32.yaml'), {}) }

      it 'finds the request operation by its custom method name' do
        request_operation = root.request_operation('COPY', '/pets')
        expect(request_operation.operation_object.class).to eq OpenAPIParser::Schemas::Operation
        expect(request_operation.http_method).to eq 'COPY'
      end

      it 'returns nil for an undeclared method' do
        expect(root.request_operation('LINK', '/pets')).to eq nil
      end
    end
  end

  describe 'OpenAPI 3.2 operations in a 3.1 document' do
    def parse_fixture(name, config = {})
      OpenAPIParser.parse(load_yaml_file("./spec/data/openapi_3_2/#{name}_31.yaml"), config)
    end

    it 'does not find a query operation, as before 3.2' do
      expect(parse_fixture('query_method').request_operation(:query, '/pets')).to eq nil
    end

    it 'does not find an additionalOperations method, as before 3.2' do
      expect(parse_fixture('additional_operations').request_operation('COPY', '/pets')).to eq nil
    end

    it 'finds both with allow_3_2_features' do
      expect(parse_fixture('query_method', { allow_3_2_features: true }).request_operation(:query, '/pets')).not_to eq nil
      expect(parse_fixture('additional_operations', { allow_3_2_features: true }).request_operation('COPY', '/pets')).not_to eq nil
    end
  end
end

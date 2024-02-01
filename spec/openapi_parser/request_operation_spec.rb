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

      it { expect(subject).to eq nil }
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

            it do
              expect { subject }.to raise_error do |e|
                expect(e).to be_kind_of(OpenAPIParser::NotExistContentTypeDefinition)
                expect(e.message).to end_with("response definition does not exist")
              end
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

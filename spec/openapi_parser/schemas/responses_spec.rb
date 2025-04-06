require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::Responses do
  describe 'correct init' do
    subject { operation.responses }

    let(:root) { OpenAPIParser.parse(petstore_schema, {}) }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/pets'] }
    let(:operation) { path_item.get }

    it do
      expect(subject.class).to eq OpenAPIParser::Schemas::Responses
      expect(subject.root.object_id).to be root.object_id

      expect(subject.object_reference).to eq '#/paths/~1pets/get/responses'
      expect(subject.default.class).to eq OpenAPIParser::Schemas::Response
      expect(subject.response['200'].class).to eq OpenAPIParser::Schemas::Response

      expect(subject.response['200'].object_reference).to eq '#/paths/~1pets/get/responses/200'
    end
  end

  describe '#validate_response_body(status_code, content_type, params)' do
    subject { responses.validate(response_body, response_validate_options) }

    let(:root) { OpenAPIParser.parse(petstore_schema, {}) }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/pets'] }
    let(:operation) { path_item.get }
    let(:responses) { operation.responses }
    let(:content_type) { 'application/json' }
    let(:response_validate_options) { OpenAPIParser::SchemaValidator::ResponseValidateOptions.new }

    let(:response_body) do
      OpenAPIParser::RequestOperation::ValidatableResponseBody.new(status_code, params, headers)
    end
    let(:headers) { { 'Content-Type' => content_type } }

    context '200' do
      let(:params) { [{ 'id' => 1, 'name' => 'name' }] }
      let(:status_code) { 200 }

      it { expect(subject).to eq([{ 'id' => 1, 'name' => 'name' }]) }
    end

    context '4XX' do
      let(:status_code) { 400 }

      context 'correct' do
        let(:params) { { 'message' => 'error' } }

        it { expect(subject).to eq({ 'message' => 'error' }) }
      end

      context 'invalid (200 response)' do
        let(:params) { [{ 'id' => 1, 'name' => 'name' }] }

        it { expect { subject }.to raise_error(OpenAPIParser::ValidateError) }
      end
    end

    context '404 (prefer use 4xx)' do
      let(:status_code) { 404 }

      context 'correct' do
        let(:params) { { 'id' => 1 } }

        it { expect(subject).to eq({ 'id' => 1 }) }
      end

      context 'invalid (4xx response)' do
        let(:params) { { 'message' => 'error' } }

        it { expect { subject }.to raise_error(OpenAPIParser::NotExistRequiredKey) }
      end
    end

    context 'invalid status code use default' do
      context 'bigger' do
        let(:status_code) { 1400 }
        let(:params) { { 'message' => 'error' } }

        it { expect { subject }.to raise_error(OpenAPIParser::NotExistRequiredKey) }
      end

      context 'smaller' do
        let(:status_code) { 40 }

        let(:params) { { 'message' => 'error' } }

        it { expect { subject }.to raise_error(OpenAPIParser::NotExistRequiredKey) }
      end
    end
  end

  describe 'response_validate_options' do
    subject { responses.validate(response_body, response_validate_options) }

    let(:root) { OpenAPIParser.parse(normal_schema, {}) }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/date_time'] }
    let(:operation) { path_item.get }
    let(:responses) { operation.responses }
    let(:content_type) { 'application/json' }
    let(:validator_options) { {} }
    let(:response_validate_options) { OpenAPIParser::SchemaValidator::ResponseValidateOptions.new(**validator_options) }

    let(:response_body) do
      OpenAPIParser::RequestOperation::ValidatableResponseBody.new(status_code, params, headers)
    end
    let(:headers) { { 'Content-Type' => content_type } }

    context 'allow_empty_date_and_datetime' do
      context 'true' do
        let(:validator_options) { { allow_empty_date_and_datetime: true } }

        context 'date' do
          context '200' do
            let(:params) { { 'date' => '' } }
            let(:status_code) { 200 }

            it { expect(subject).to eq({ 'date' => '' }) }
          end

          context '400' do
            let(:params) { { 'date' => '' } }
            let(:status_code) { 400 }

            it { expect(subject).to eq(nil) }
          end
        end

        context 'date-time' do
          context '200' do
            let(:params) { { 'date-time' => '' } }
            let(:status_code) { 200 }

            it { expect(subject).to eq({ 'date-time' => '' }) }
          end

          context '400' do
            let(:params) { { 'date-time' => '' } }
            let(:status_code) { 400 }

            it { expect(subject).to eq(nil) }
          end
        end
      end

      context 'false' do
        let(:validator_options) { { allow_empty_date_and_datetime: false } }

        context 'date' do
          context '200' do
            let(:params) { { 'date' => '' } }
            let(:status_code) { 200 }

            it do
              expect { subject }.to raise_error do |e|
                expect(e).to be_kind_of(OpenAPIParser::InvalidDateFormat)
                expect(e.message).to end_with("Value: \"\" is not conformant with date format")
              end
            end
          end

          context '400' do
            let(:params) { { 'date' => '' } }
            let(:status_code) { 400 }

            it { expect(subject).to eq(nil) }
          end
        end

        context 'date-time' do
          context '200' do
            let(:params) { { 'date-time' => '' } }
            let(:status_code) { 200 }

            it do
              expect { subject }.to raise_error do |e|
                expect(e).to be_kind_of(OpenAPIParser::InvalidDateTimeFormat)
                expect(e.message).to end_with("Value: \"\" is not conformant with date-time format")
              end
            end
          end

          context '400' do
            let(:params) { { 'date-time' => '' } }
            let(:status_code) { 400 }

            it { expect(subject).to eq(nil) }
          end
        end
      end
    end
  end

  describe 'resolve reference init' do
    subject { operation.responses }

    let(:schema) { YAML.load_file('./spec/data/reference_in_responses.yaml') }
    let(:root) { OpenAPIParser.parse(schema, {}) }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/info'] }
    let(:operation) { path_item.get }
    let(:response_object) { subject.response['200'] }

    it do
      expect(response_object.class).to eq OpenAPIParser::Schemas::Response
      expect(response_object.description).to eq 'reference response'
    end
  end
end

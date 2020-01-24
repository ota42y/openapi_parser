require_relative '../spec_helper'

RSpec.describe OpenAPIParser::ParameterValidator do
  let(:root) { OpenAPIParser.parse(normal_schema, config) }
  let(:config) { {} }

  describe 'validate' do
    subject { request_operation.validate_request_parameter(params, {}) }

    let(:content_type) { 'application/json' }
    let(:http_method) { :get }
    let(:request_path) { '/validate' }
    let(:request_operation) { root.request_operation(http_method, request_path) }
    let(:params) { {} }

    context 'correct' do
      context 'no optional' do
        let(:params) { { 'query_string' => 'query', 'query_integer_list' => [1, 2], 'queryString' => 'Query' } }
        it { expect(subject).to eq({ 'query_string' => 'query', 'query_integer_list' => [1, 2], 'queryString' => 'Query' }) }
      end

      context 'with optional' do
        let(:params) { { 'query_string' => 'query', 'query_integer_list' => [1, 2], 'queryString' => 'Query', 'optional_integer' => 1 } }
        it { expect(subject).to eq({ 'optional_integer' => 1, 'query_integer_list' => [1, 2], 'queryString' => 'Query', 'query_string' => 'query' }) }
      end
    end

    context 'invalid' do
      context 'not exist required' do
        context 'not exist data' do
          let(:params) { { 'query_integer_list' => [1, 2], 'queryString' => 'Query' } }

          it do
            expect { subject }.to raise_error do |e|
              expect(e).to be_kind_of(OpenAPIParser::NotExistRequiredKey)
              expect(e.message).to end_with('missing required parameters: query_string')
            end
          end
        end

        context 'not exist array' do
          let(:params) { { 'query_string' => 'query', 'queryString' => 'Query' } }

          it do
            expect { subject }.to raise_error do |e|
              expect(e).to be_kind_of(OpenAPIParser::NotExistRequiredKey)
              expect(e.message).to end_with('missing required parameters: query_integer_list')
            end
          end
        end
      end

      context 'non null check' do
        context 'optional' do
          let(:params) { { 'query_string' => 'query', 'query_integer_list' => [1, 2], 'queryString' => 'Query', 'optional_integer' => nil } }
          it { expect { subject }.to raise_error(OpenAPIParser::NotNullError) }
        end

        context 'optional' do
          let(:params) { { 'query_string' => 'query', 'query_integer_list' => nil, 'queryString' => 'Query' } }
          it { expect { subject }.to raise_error(OpenAPIParser::NotNullError) }
        end
      end
    end

    context 'nested query params in post request' do
      let(:http_method) { :post }
      let(:request_path) { '/validate-nested' }
      let(:config) do
        {
          coerce_value: true,
          datetime_coerce_class: DateTime
        }
      end

      context 'with required params, nested' do
        let(:params) do
          {
            'nested_object' => {
              'name' => 'hello',
              'value' => '2016-04-01T16:00:00+09:00'
            },
            'nested_but_flat_object' => {
              'name' => 'hello',
              'value' => '2016-04-01T16:00:00+09:00'
            }
          }
        end

        it { expect(subject['nested_but_flat_object']['name']).to eq('hello') }
        it { expect(subject['nested_but_flat_object']['value']).to be_an_instance_of(DateTime) }
        it { expect(subject['nested_object']['value']).to be_an_instance_of(DateTime) }
      end

      context 'without required nested param' do
        let(:params) do
          {
            'nested_object' => {
              'name' => 'hello',
              'value' => '2016-04-01T16:00:00+09:00'
            },
            'nested_but_flat_object' => {
              'value' => '2016-04-01T16:00:00+09:00'
            }
          }
        end

        it do
          expect { subject }.to raise_error do |e|
            expect(e).to be_kind_of(OpenAPIParser::NotExistRequiredKey)
            expect(e.message).to end_with('missing required parameters: nested_but_flat_object[name]')
          end
        end
      end

      context 'without required parent param' do
        let(:params) do
          {
            'nested_object' => {
              'name' => 'hello',
              'value' => '2016-04-01T16:00:00+09:00'
            }
          }
        end

        it do
          expect { subject }.to raise_error do |e|
            expect(e).to be_kind_of(OpenAPIParser::NotExistRequiredKey)
            expect(e.message).to end_with('missing required parameters: nested_but_flat_object[name], nested_but_flat_object[value]')
          end
        end
      end
    end
  end
end

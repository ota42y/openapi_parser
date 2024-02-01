require_relative '../spec_helper'

RSpec.describe OpenAPIParser::SchemaValidator do
  let(:root) { OpenAPIParser.parse(normal_schema, config) }
  let(:config) { {} }

  describe 'validate_request_body' do
    subject { request_operation.validate_request_body('application/json', params) }

    let(:content_type) { 'application/json' }
    let(:http_method) { :post }
    let(:request_path) { '/validate' }
    let(:request_operation) { root.request_operation(http_method, request_path) }
    let(:params) { {} }

    it 'correct' do
      params = [
        ['string', 'str'],
        ['integer', 1],
        ['boolean', true],
        ['boolean', false],
        ['number', 0.1],
      ].to_h

      ret = request_operation.validate_request_body(content_type, params)
      expect(ret).to eq({ 'boolean' => false, 'integer' => 1, 'number' => 0.1, 'string' => 'str' })
    end

    it 'number allow integer' do
      params = { 'number' => 1 }

      ret = request_operation.validate_request_body(content_type, params)
      expect(ret).to eq({ 'number' => 1 })
    end

    it 'correct object data' do
      params = {
        'object_1' =>
            {
              'string_1' => nil,
              'integer_1' => nil,
              'boolean_1' => nil,
              'number_1' => nil,
            },
      }

      ret = request_operation.validate_request_body(content_type, params)
      expect(ret).to eq({ 'object_1' => { 'boolean_1' => nil, 'integer_1' => nil, 'number_1' => nil, 'string_1' => nil } })
    end

    it 'invalid params' do
      invalids = [
        ['string', 1],
        ['string', true],
        ['string', false],
        ['integer', '1'],
        ['integer', 0.1],
        ['integer', true],
        ['integer', false],
        ['boolean', 1],
        ['boolean', 'true'],
        ['boolean', 'false'],
        ['boolean', '0.1'],
        ['number', '0.1'],
        ['number', true],
        ['number', false],
        ['array', false],
        ['array', 1],
        ['array', true],
        ['array', '1'],
      ]

      invalids.each do |key, value|
        params = { key.to_s => value }

        expect { request_operation.validate_request_body(content_type, params) }.to raise_error do |e|
          expect(e).to be_kind_of(OpenAPIParser::ValidateError)
          expect(e.message).to end_with("expected #{key}, but received #{value.class}: #{value.inspect}")
        end
      end
    end

    it 'required params' do
      object = {
        'string_2' => 'str',
        'integer_2' => 1,
        'boolean_2' => true,
        'number_2' => 0.1,
      }

      object.keys.each do |key|
        deleted_object = object.reject { |k, _v| k == key }
        params = { 'object_2' => deleted_object }
        expect { request_operation.validate_request_body(content_type, params) }.to raise_error do |e|
          expect(e).to be_kind_of(OpenAPIParser::NotExistRequiredKey)
          expect(e.message).to end_with("missing required parameters: #{key}")
        end
      end

      params = { 'object_2' => {} }
      expect { request_operation.validate_request_body(content_type, params) }.to raise_error do |e|
        expect(e).to be_kind_of(OpenAPIParser::NotExistRequiredKey)
        expect(e.message).to end_with("missing required parameters: #{object.keys.join(", ")}")
      end
    end

    context 'nested required params' do
      subject { request_operation.validate_request_body(content_type, { 'required_object' => required_object }) }

      let(:required_object_base) do
        JSON.parse(
          {
            need_object: {
              string: 'abc',
            },
            no_need_object: {
              integer: 1,
            },
          }.to_json,
        )
      end
      let(:required_object) { required_object_base }

      context 'normal' do
        it { expect(subject).to eq({ 'required_object' => { 'need_object' => { 'string' => 'abc' }, 'no_need_object' => { 'integer' => 1 } } }) }
      end

      context 'no need object delete' do
        let(:required_object) do
          required_object_base.delete 'no_need_object'
          required_object_base
        end
        it { expect(subject).to eq({ 'required_object' => { 'need_object' => { 'string' => 'abc' } } }) }
      end

      context 'delete required params' do
        let(:required_object) do
          required_object_base['need_object'].delete 'string'
          required_object_base
        end
        it do
          expect { subject }.to raise_error do |e|
            expect(e).to be_kind_of(OpenAPIParser::NotExistRequiredKey)
            expect(e.message).to end_with('missing required parameters: string')
          end
        end
      end

      context 'required object not exist' do
        let(:required_object) do
          required_object_base.delete 'need_object'
          required_object_base
        end
        it do
          expect { subject }.to raise_error do |e|
            expect(e).to be_kind_of(OpenAPIParser::NotExistRequiredKey)
            expect(e.message).to end_with('missing required parameters: need_object')
          end
        end
      end
    end

    describe 'array' do
      subject { request_operation.validate_request_body(content_type, { 'array' => array_data }) }

      context 'correct' do
        let(:array_data) { [1] }
        it { expect(subject).to eq({ 'array' => [1] }) }
      end

      context 'other value include' do
        let(:array_data) { [1, 1.1] }

        it do
          expect { subject }.to raise_error do |e|
            expect(e).to be_kind_of(OpenAPIParser::ValidateError)
            expect(e.message).to end_with("expected integer, but received Float: 1.1")
          end
        end
      end

      context 'empty' do
        let(:array_data) { [] }
        it { expect(subject).to eq({ 'array' => [] }) }
      end

      context 'nil' do
        let(:array_data) { [nil] }

        it do
          expect { subject }.to raise_error do |e|
            expect(e).to be_kind_of(OpenAPIParser::NotNullError)
            expect(e.message.include?("does not allow null values")).to eq true
          end
        end
      end

      context 'anyOf' do
        it do
          expect(request_operation.validate_request_body(content_type, { 'any_of' => ['test', true] })).
            to eq({ 'any_of' => ['test', true] })
        end

        it 'invalid' do
          expect { request_operation.validate_request_body(content_type, { 'any_of' => [1] }) }.to raise_error do |e|
            expect(e.kind_of?(OpenAPIParser::NotAnyOf)).to eq true
            expect(e.message.start_with?("1 isn't any of")).to eq true
          end
        end
      end

      context 'anyOf with nullable' do
        subject { request_operation.validate_request_body(content_type, { 'any_of_with_nullable' => params }) }

        context 'integer' do
          let(:params) { 1 }

          it { expect(subject).to eq({ 'any_of_with_nullable' => 1 }) }
        end

        context 'null' do
          let(:params) { nil }

          it { expect(subject).to eq({ 'any_of_with_nullable' => nil }) }
        end

        context 'invalid' do
          let(:params) { 'foo' }

          it { expect { subject }.to raise_error(OpenAPIParser::NotAnyOf) }
        end
      end

      context 'unspecified_type' do
        it do
          expect(request_operation.validate_request_body(content_type, { 'unspecified_type' => "foo" })).
            to eq({ 'unspecified_type' => "foo" })
        end

        it do
          expect(request_operation.validate_request_body(content_type, { 'unspecified_type' => [1, 2] })).
            to eq({ 'unspecified_type' => [1, 2] })
        end
      end
    end

    describe 'object' do
      subject { request_operation.validate_request_body(content_type, { 'object_1' => object_data }) }

      context 'correct' do
        let(:object_data) { {} }
        it { expect(subject).to eq({ 'object_1' => {} }) }
      end

      context 'not object' do
        let(:object_data) { [] }

        it do
          expect { subject }.to raise_error do |e|
            expect(e).to be_kind_of(OpenAPIParser::ValidateError)
            expect(e.message).to end_with("expected object, but received Array: []")
          end
        end
      end
    end

    describe 'enum' do
      context 'enum string' do
        it 'include enum' do
          ['a', 'b'].each do |str|
            expect(request_operation.validate_request_body(content_type, { 'enum_string' => str })).
              to eq({ 'enum_string' => str })
          end
        end

        it 'not include enum' do
          expect { request_operation.validate_request_body(content_type, { 'enum_string' => 'x' }) }.to raise_error do |e|
            expect(e.kind_of?(OpenAPIParser::NotEnumInclude)).to eq true
            expect(e.message.start_with?("\"x\" isn't part of the enum")).to eq true
          end
        end

        it 'not include enum (empty string)' do
          expect { request_operation.validate_request_body(content_type, { 'enum_string' => '' }) }.to raise_error do |e|
            expect(e.kind_of?(OpenAPIParser::NotEnumInclude)).to eq true
            expect(e.message.start_with?("\"\" isn't part of the enum")).to eq true
          end
        end
      end

      context 'enum integer' do
        it 'include enum' do
          [1, 2].each do |str|
            expect(request_operation.validate_request_body(content_type, { 'enum_integer' => str })).
              to eq({ 'enum_integer' => str })
          end
        end

        it 'not include enum' do
          expect { request_operation.validate_request_body(content_type, { 'enum_integer' => 3 }) }.to raise_error do |e|
            expect(e.kind_of?(OpenAPIParser::NotEnumInclude)).to eq true
            expect(e.message.start_with?("3 isn't part of the enum")).to eq true
          end
        end
      end

      context 'enum number' do
        it 'include enum' do
          [1.0, 2.1].each do |str|
            expect(request_operation.validate_request_body(content_type, { 'enum_number' => str })).
              to eq({ 'enum_number' => str })
          end
        end

        it 'not include enum' do
          expect { request_operation.validate_request_body(content_type, { 'enum_number' => 1.1 }) }.to raise_error do |e|
            expect(e.kind_of?(OpenAPIParser::NotEnumInclude)).to eq true
            expect(e.message.start_with?("1.1 isn't part of the enum")).to eq true
          end
        end
      end

      context 'enum boolean' do
        it 'include enum' do
          expect(request_operation.validate_request_body(content_type, { 'enum_boolean' => true })).
            to eq({ 'enum_boolean' => true })
        end

        it 'not include enum' do
          expect { request_operation.validate_request_body(content_type, { 'enum_boolean' => false }) }.to raise_error do |e|
            expect(e.kind_of?(OpenAPIParser::NotEnumInclude)).to eq true
            expect(e.message.start_with?("false isn't part of the enum")).to eq true
          end
        end
      end
    end

    describe 'all_of' do
      subject { request_operation.validate_request_body(content_type, { 'all_of_data' => params }) }

      let(:correct_params) do
        {
          'id' => 1,
          'name' => 'name_dana',
          'tag' => 'tag_data',
        }
      end
      let(:params) { correct_params }

      it { expect(subject).not_to eq nil }

      context 'option value deleted' do
        let(:params) do
          d = correct_params
          d.delete('tag')
          d
        end

        it { expect(subject).not_to eq nil }
      end

      context 'not any_of schema in first' do
        let(:params) do
          d = correct_params
          d.delete('name')
          d
        end

        it { expect { subject }.to raise_error(::OpenAPIParser::NotExistRequiredKey) }
      end

      context 'not any_of schema in second' do
        context 'not exist required key' do
          let(:params) do
            d = correct_params
            d.delete('id')
            d
          end

          it { expect { subject }.to raise_error(::OpenAPIParser::NotExistRequiredKey) }
        end

        context 'type error' do
          let(:params) do
            correct_params['id'] = 'abc'
            correct_params
          end

          it { expect { subject }.to raise_error(::OpenAPIParser::ValidateError) }
        end
      end
    end

    describe 'allOf with nullable' do
      context 'with nullable' do
        subject { request_operation.validate_request_body(content_type, { 'all_of_with_nullable' => params }) }

        context 'integer' do
          let(:params) { 1 }

          it { expect(subject).to eq({ 'all_of_with_nullable' => 1 }) }
        end

        context 'null' do
          let(:params) { nil }

          it { expect(subject).to eq({ 'all_of_with_nullable' => nil }) }
        end

        context 'invalid' do
          let(:params) { 'foo' }

          it { expect { subject }.to raise_error(::OpenAPIParser::ValidateError) }
        end
      end
    end

    describe 'one_of' do
      context 'normal' do
        subject { request_operation.validate_request_body(content_type, { 'one_of_data' => params }) }

        let(:correct_params) do
          {
            'name' => 'name',
            'integer_1' => 42,
          }
        end
        let(:params) { correct_params }

        it { expect(subject).not_to eq nil }

        context 'no schema matched' do
          let(:params) do
            {
              'integer_1' => 42,
            }
          end

          it do
            expect { subject }.to raise_error do |e|
              expect(e.kind_of?(OpenAPIParser::NotOneOf)).to eq true
              expect(e.message.include?("isn't one of")).to eq true
            end
          end
        end

        context 'multiple schema matched' do
          let(:params) do
            {
              'name' => 'name',
              'integer_1' => 42,
              'string_1' => 'string_1',
            }
          end

          it do
            expect { subject }.to raise_error do |e|
              expect(e.kind_of?(OpenAPIParser::NotOneOf)).to eq true
              expect(e.message.include?("isn't one of")).to eq true
            end
          end
        end
      end

      context 'with discriminator' do
        subject { request_operation.validate_request_body(content_type, { 'one_of_with_discriminator' => params }) }

        let(:correct_params) do
          {
            'objType' => 'obj1',
            'name' => 'name',
            'integer_1' => 42,
          }
        end
        let(:params) { correct_params }

        it { expect(subject).not_to eq nil }
      end

      context 'with nullable' do
        subject { request_operation.validate_request_body(content_type, { 'one_of_with_nullable' => params }) }

        context 'integer' do
          let(:params) { 1 }

          it { expect(subject).to eq({ 'one_of_with_nullable' => 1 }) }
        end

        context 'null' do
          let(:params) { nil }

          it { expect(subject).to eq({ 'one_of_with_nullable' => nil }) }
        end

        context 'invalid' do
          let(:params) { 'foo' }

          it { expect { subject }.to raise_error(OpenAPIParser::NotOneOf) }
        end
      end
    end

    it 'unknown param' do
      expect { request_operation.validate_request_body(content_type, { 'unknown' => 1 }) }.to raise_error do |e|
        expect(e).to be_kind_of(OpenAPIParser::NotExistPropertyDefinition)
        expect(e.message).to end_with("does not define properties: unknown")
      end
    end
  end

  describe 'coerce' do
    subject { request_operation.validate_request_parameter(params, {}) }

    let(:config) { { coerce_value: true } }

    let(:content_type) { 'application/json' }
    let(:http_method) { :get }
    let(:request_path) { '/string_params_coercer' }
    let(:request_operation) { root.request_operation(http_method, request_path) }
    let(:params) { { key.to_s => value.to_s } }

    let(:nested_array) do
      [
        {
          'update_time' => '2016-04-01T16:00:00.000+09:00',
          'per_page' => '1',
          'nested_coercer_object' => {
            'update_time' => '2016-04-01T16:00:00.000+09:00',
            'threshold' => '1.5',
          },
          'nested_no_coercer_object' => {
            'per_page' => '1',
            'threshold' => '1.5',
          },
          'nested_coercer_array' => [
            {
              'update_time' => '2016-04-01T16:00:00.000+09:00',
              'threshold' => '1.5',
            },
          ],
          'nested_no_coercer_array' => [
            {
              'per_page' => '1',
              'threshold' => '1.5',
            },
          ],
        },
        {
          'update_time' => '2016-04-01T16:00:00.000+09:00',
          'per_page' => '1',
          'threshold' => '1.5',
        },
        {
          'threshold' => '1.5',
          'per_page' => '1',
        },
      ]
    end

    context 'request_body' do
      subject { request_operation.validate_request_body(content_type, params) }

      let(:http_method) { :post }
      let(:params) { { 'nested_array' => nested_array } }
      let(:config) { { coerce_value: true, datetime_coerce_class: DateTime } }

      context 'correct' do
        it do
          subject

          nested_array = params['nested_array']
          first_data = nested_array[0]
          expect(first_data['update_time'].class).to eq DateTime
          expect(first_data['per_page'].class).to eq Integer
        end
      end

      context 'datetime' do
        let(:params) { { 'datetime' => datetime_str, 'string' => 'str' } }
        let(:request_path) { '/validate' }

        let(:datetime_str) { '2016-04-01T16:00:00+09:00' }

        it do
          subject

          expect(params['datetime'].class).to eq DateTime
          expect(params['string'].class).to eq String
        end
      end

      context 'overwrite initialize option' do
        subject { request_operation.validate_request_body(content_type, params, options) }

        let(:options) { OpenAPIParser::SchemaValidator::Options.new(coerce_value: false) }

        it do
          expect { subject }.to raise_error(OpenAPIParser::ValidateError)
        end
      end

      context 'anyOf' do
        where(:before_value, :result_value) do
          [
            [true, true],
            ['true', true],
            ['3.5', 3.5],
            [3.5, 3.5],
            [10, 10],
            ['10', 10],
            %w[pineapple pineapple]
          ]
        end

        with_them do
          let(:params) { { 'any_of' => before_value } }
          it do
            expect(subject).to eq({ 'any_of' => result_value })
            expect(params['any_of']).to eq result_value
          end
        end
      end
    end

    context 'string' do
      context "doesn't coerce params not in the schema" do
        let(:params) { { 'owner' => 'admin' } }

        it do
          expect(subject).to eq({ 'owner' => 'admin' })
          expect(params['owner']).to eq 'admin'
        end
      end

      context 'skips values for string param' do
        let(:params) { { key.to_s => value.to_s } }
        let(:key) { 'string_1' }
        let(:value) { 'foo' }

        it do
          expect(subject).to eq({ key.to_s => value.to_s })
          expect(params[key]).to eq value
        end
      end
    end

    context 'boolean' do
      let(:key) { 'boolean_1' }

      context 'coerces valid values for boolean param' do
        where(:before_value, :result_value) do
          [
            ['true', true],
            ['false', false],
            ['1', true],
            ['0', false],
          ]
        end

        with_them do
          let(:value) { before_value }
          it do
            expect(subject).to eq({ key.to_s => result_value })
            expect(params[key]).to eq result_value
          end
        end
      end

      context 'skips invalid values for boolean param' do
        let(:value) { 'foo' }

        it do
          expect { subject }.to raise_error(OpenAPIParser::ValidateError)
        end
      end
    end

    context 'integer' do
      let(:key) { 'integer_1' }

      context 'coerces valid values for integer param' do
        let(:value) { '3' }
        let(:params) { { key.to_s => value.to_s } }

        it do
          expect(subject).to eq({ key.to_s => 3 })
          expect(params[key]).to eq 3
        end

        context 'overwrite initialize option' do
          subject { request_operation.validate_request_parameter(params, {}, options) }

          let(:options) { OpenAPIParser::SchemaValidator::Options.new(coerce_value: false) }

          it do
            expect { subject }.to raise_error(OpenAPIParser::ValidateError)
          end
        end
      end

      context 'skips invalid values for integer param' do
        using RSpec::Parameterized::TableSyntax

        where(:before_value) { ['3.5', 'false', ''] }

        with_them do
          let(:value) { before_value }
          it do
            expect { subject }.to raise_error(OpenAPIParser::ValidateError)
          end
        end
      end
    end

    context 'number' do
      let(:key) { 'number_1' }

      context 'coerces valid values for number param' do
        where(:before_value, :result_value) do
          [
            ['3', 3.0],
            ['3.5', 3.5],
          ]
        end

        with_them do
          let(:value) { before_value }
          it do
            expect(subject).to eq({ key.to_s => result_value })
            expect(params[key]).to eq result_value
          end
        end
      end

      context 'invalid values' do
        let(:value) { 'false' }

        it do
          expect { subject }.to raise_error(OpenAPIParser::ValidateError)
        end
      end
    end

    describe 'array' do
      context 'normal array' do
        let(:params) do
          {
            'normal_array' => [
              '1',
            ],
          }
        end

        it do
          expect(subject['normal_array'][0]).to eq 1
          expect(params['normal_array'][0]).to eq 1
        end
      end

      context 'nested_array' do
        let(:params) do
          { 'nested_array' => nested_array }
        end
        let(:coerce_date_times) { false }

        it do
          subject

          nested_array = params['nested_array']
          first_data = nested_array[0]
          expect(first_data['update_time'].class).to eq String
          expect(first_data['per_page'].class).to eq Integer

          second_data = nested_array[1]
          expect(second_data['update_time'].class).to eq String
          expect(first_data['per_page'].class).to eq Integer
          expect(second_data['threshold'].class).to eq Float

          third_data = nested_array[2]
          expect(first_data['per_page'].class).to eq Integer
          expect(third_data['threshold'].class).to eq Float

          expect(first_data['nested_coercer_object']['update_time'].class).to eq String
          expect(first_data['nested_coercer_object']['threshold'].class).to eq Float

          expect(first_data['nested_no_coercer_object']['per_page'].class).to eq String
          expect(first_data['nested_no_coercer_object']['threshold'].class).to eq String

          expect(first_data['nested_coercer_array'].first['update_time'].class).to eq String
          expect(first_data['nested_coercer_array'].first['threshold'].class).to eq Float

          expect(first_data['nested_no_coercer_array'].first['per_page'].class).to eq String
          expect(first_data['nested_no_coercer_array'].first['threshold'].class).to eq String
        end
      end
    end

    context 'datetime_coercer' do
      let(:config) { { coerce_value: true, datetime_coerce_class: DateTime } }

      context 'correct datetime' do
        let(:params) { { 'datetime_string' => '2016-04-01T16:00:00.000+09:00' } }

        it do
          expect(subject['datetime_string'].class).to eq DateTime
          expect(params['datetime_string'].class).to eq DateTime
        end
      end

      context 'correct Time' do
        let(:params) { { 'datetime_string' => '2016-04-01T16:00:00.000+09:00' } }
        let(:config) { { coerce_value: true, datetime_coerce_class: Time } }

        it do
          expect(subject['datetime_string'].class).to eq Time
          expect(params['datetime_string'].class).to eq Time
        end
      end

      context 'invalid datetime raise validation error' do
        let(:params) { { 'datetime_string' => 'honoka' } }

        it { expect { subject }.to raise_error(OpenAPIParser::InvalidDateTimeFormat) }
      end

      context "don't change object type" do
        class HashLikeObject < Hash; end

        let(:params) do
          h = HashLikeObject.new
          h['datetime_string'] = '2016-04-01T16:00:00.000+09:00'
          h
        end

        it do
          expect(subject['datetime_string'].class).to eq DateTime
          expect(subject.class).to eq HashLikeObject
        end
      end

      context 'nested array' do
        let(:params) { { 'nested_array' => nested_array } }
        it do
          subject

          nested_array = params['nested_array']
          first_data = nested_array[0]
          expect(first_data['update_time'].class).to eq DateTime

          second_data = nested_array[1]
          expect(second_data['update_time'].class).to eq DateTime

          expect(first_data['nested_coercer_object']['update_time'].class).to eq DateTime
          expect(first_data['nested_coercer_array'][0]['update_time'].class).to eq DateTime
        end
      end
    end

    context 'anyOf' do
      let(:key) { 'any_of' }

      context 'coerces valid values for any_of param' do
        where(:before_value, :result_value) do
          [
            ['true', true],
            ['3.5', 3.5],
            ['10', 10]
          ]
        end

        with_them do
          let(:value) { before_value }
          it do
            expect(subject).to eq({ key.to_s => result_value })
            expect(params[key]).to eq result_value
          end
        end
      end

      context 'invalid values' do
        let(:value) { 'pineapple' }

        it do
          expect { subject }.to raise_error(OpenAPIParser::NotAnyOf)
        end
      end
    end
  end

  describe 'coerce path parameter' do
    subject { request_operation.validate_path_params }

    let(:content_type) { 'application/json' }
    let(:request_operation) { root.request_operation(http_method, request_path) }
    let(:http_method) { :get }
    let(:config) { { coerce_value: true } }

    context 'correct in operation object' do
      let(:request_path) { '/coerce_path_params/1' }
      it do
        expect(request_operation.path_params).to eq({ 'integer' => '1' })

        subject

        expect(request_operation.path_params).to eq({ 'integer' => 1 })
      end
    end

    context 'correct in path item object' do
      let(:request_path) { '/coerce_path_params_in_path_item/1' }
      it do
        expect(request_operation.path_params).to eq({ 'integer' => '1' })

        subject

        expect(request_operation.path_params).to eq({ 'integer' => 1 })
      end
    end
  end

  describe 'coerce query parameter' do
    subject { request_operation.validate_request_parameter(params, headers) }

    let(:root) { OpenAPIParser.parse(normal_schema, config) }
    let(:content_type) { 'application/json' }

    let(:http_method) { :get }
    let(:request_path) { '/coerce_query_prams_in_operation_and_path_item' }
    let(:request_operation) { root.request_operation(http_method, request_path) }
    let(:params) { {} }
    let(:headers) { {} }
    let(:config) { { coerce_value: true } }

    context 'correct in all params' do
      let(:params) { {'operation_integer' => '1', 'path_item_integer' => '2'} }
      let(:correct) { {'operation_integer' => 1, 'path_item_integer' => 2} }
      it { expect(subject).to eq(correct) }
    end

    context 'invalid operation integer only' do
      let(:params) { {'operation_integer' => '1'} }
      it { expect{subject}.to raise_error(OpenAPIParser::NotExistRequiredKey) }
    end
    context 'invalid path_item integer only' do
      let(:params) { {'path_item_integer' => '2'} }
      it { expect{subject}.to raise_error(OpenAPIParser::NotExistRequiredKey) }
    end
  end

  describe 'validate header in parameter' do
    subject do
      request_operation.validate_request_parameter(params, headers)
    end

    let(:root) { OpenAPIParser.parse(petstore_schema, config) }
    let(:content_type) { 'application/json' }

    let(:http_method) { :get }
    let(:request_path) { '/animals/1' }
    let(:request_operation) { root.request_operation(http_method, request_path) }
    let(:params) { {} }
    let(:headers) { {} }

    context 'invalid header' do
      context 'path item require' do
        let(:headers) { { 'header_2' => 'h' } }
        it { expect { subject }.to raise_error(OpenAPIParser::NotExistRequiredKey) }
      end

      context 'operation require' do
        let(:headers) { { 'token' => 1 } }
        it { expect { subject }.to raise_error(OpenAPIParser::NotExistRequiredKey) }
      end
    end

    context 'valid header' do
      let(:headers) { { 'TOKEN' => 1, 'header_2' => 'h' } }

      it { expect(subject).not_to eq nil }

      context 'with validate_header = false' do
        let(:config) { { validate_header: false } }

        context 'path item require' do
          let(:headers) { { 'header_2' => 'h' } }
          it { expect(subject).not_to eq nil }
        end

        context 'operation require' do
          let(:headers) { { 'token' => 1 } }
          it { expect(subject).not_to eq nil }
        end
      end
    end
  end

  describe 'validatable' do
    class ValidatableTest
      include OpenAPIParser::SchemaValidator::Validatable
    end

    describe 'validate_schema' do
      subject { ValidatableTest.new.validate_schema(nil, nil) }

      it { expect { subject }.to raise_error(StandardError).with_message('implement') }
    end

    describe 'validate_integer(value, schema)' do
      subject { ValidatableTest.new.validate_integer(nil, nil) }

      it { expect { subject }.to raise_error(StandardError).with_message('implement') }
    end
  end
end

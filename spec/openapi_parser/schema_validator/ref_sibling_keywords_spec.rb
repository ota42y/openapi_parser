require_relative '../../spec_helper'

RSpec.describe 'keywords next to $ref' do
  let(:openapi_version) { '3.1.0' }
  let(:strict_reference_validation) { true }
  let(:options) { ::OpenAPIParser::SchemaValidator::Options.new }
  let(:coerce_options) { ::OpenAPIParser::SchemaValidator::Options.new(coerce_value: true) }
  let(:base_schemas) do
    {
      'Name' => { 'type' => 'string' },
      'Count' => { 'type' => 'integer' },
      'Item' => { 'type' => 'object', 'properties' => { 'id' => { 'type' => 'integer' } } },
    }
  end
  let(:root) do
    raw = {
      'openapi' => openapi_version,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => paths,
      'components' => { 'schemas' => base_schemas.merge('Target' => target) },
    }
    OpenAPIParser.parse(raw, strict_reference_validation: strict_reference_validation)
  end
  let(:paths) { {} }
  let(:schema) { root.components.schemas['Target'] }

  def validate(value, validate_options = options)
    OpenAPIParser::SchemaValidator.validate(value, schema, validate_options)
  end

  context 'when a keyword is next to $ref' do
    let(:target) { { '$ref' => '#/components/schemas/Name', 'maxLength' => 3 } }

    it 'rejects a value that breaks the keyword' do
      expect { validate('abcd') }.to raise_error(OpenAPIParser::MoreThanMaxLength)
    end

    it 'accepts a value that satisfies both' do
      expect(validate('abc')).to eq 'abc'
    end

    it 'rejects a value that breaks the referenced schema' do
      expect { validate(1) }.to raise_error(OpenAPIParser::ValidateError)
    end

    it 'reports the path of the schema' do
      expect { validate('abcd') }.to raise_error(%r{#/components/schemas/Target })
    end
  end

  context 'when required is next to $ref' do
    let(:target) { { '$ref' => '#/components/schemas/Item', 'required' => ['id'] } }

    it 'rejects an object without the property' do
      expect { validate({}) }.to raise_error(OpenAPIParser::NotExistRequiredKey)
    end
  end

  context 'when properties are next to $ref' do
    let(:target) { { '$ref' => '#/components/schemas/Item', 'properties' => { 'name' => { 'type' => 'string' } } } }

    it 'checks the properties' do
      expect { validate({ 'id' => 1, 'name' => 1 }) }.to raise_error(OpenAPIParser::ValidateError)
      value = { 'id' => 1, 'name' => 'a' }
      expect(validate(value)).to eq value
    end
  end

  context 'when additionalProperties: false is next to $ref' do
    let(:target) { { '$ref' => '#/components/schemas/Item', 'additionalProperties' => false } }

    it 'rejects a property defined only in the referenced schema' do
      expect { validate({ 'id' => 1 }) }.to raise_error(OpenAPIParser::NotExistPropertyDefinition)
    end
  end

  context 'when only annotations are next to $ref' do
    let(:target) { { '$ref' => '#/components/schemas/Name', 'description' => 'd', 'x-foo' => 1 } }

    it 'is the referenced schema' do
      expect(schema).to be root.components.schemas['Name']
    end
  end

  context 'when code reads the schema' do
    let(:target) { { '$ref' => '#/components/schemas/Item', 'required' => ['id'] } }

    it 'returns the type of the referenced schema' do
      expect(schema.type).to eq 'object'
    end

    it 'returns the properties of the referenced schema' do
      expect(schema.properties.keys).to eq ['id']
    end
  end

  context 'when the schema is in other places' do
    let(:with_ref) { { '$ref' => '#/components/schemas/Name', 'maxLength' => 3 } }

    context 'with a property' do
      let(:target) { { 'type' => 'object', 'properties' => { 'a' => with_ref } } }

      it 'checks it' do
        expect { validate({ 'a' => 'abcd' }) }.to raise_error(OpenAPIParser::MoreThanMaxLength)
      end
    end

    context 'with items' do
      let(:target) { { 'type' => 'array', 'items' => with_ref } }

      it 'checks it' do
        expect { validate(['abcd']) }.to raise_error(OpenAPIParser::MoreThanMaxLength)
      end
    end

    context 'with a member of allOf' do
      let(:target) { { 'allOf' => [with_ref] } }

      it 'checks it' do
        expect { validate('abcd') }.to raise_error(OpenAPIParser::MoreThanMaxLength)
      end
    end

    context 'with a member of anyOf' do
      let(:target) { { 'anyOf' => [with_ref] } }

      it 'checks it' do
        expect { validate('abcd') }.to raise_error(OpenAPIParser::NotAnyOf)
      end
    end

    context 'with a member of oneOf' do
      let(:target) { { 'oneOf' => [with_ref] } }

      it 'checks it' do
        expect { validate('abcd') }.to raise_error(OpenAPIParser::NotOneOf)
      end
    end
  end

  context 'when the referenced schema also has a keyword next to $ref' do
    let(:base_schemas) do
      {
        'Name' => { 'type' => 'string' },
        'Short' => { '$ref' => '#/components/schemas/Name', 'maxLength' => 3 },
      }
    end
    let(:target) { { '$ref' => '#/components/schemas/Short', 'minLength' => 2 } }

    it 'checks both' do
      expect(validate('ab')).to eq 'ab'
      expect { validate('a') }.to raise_error(OpenAPIParser::LessThanMinLength)
      expect { validate('abcd') }.to raise_error(OpenAPIParser::MoreThanMaxLength)
    end
  end

  context 'when a composition keyword is next to $ref' do
    context 'with allOf' do
      let(:target) { { '$ref' => '#/components/schemas/Name', 'allOf' => [{ 'maxLength' => 3 }] } }

      it 'checks it' do
        expect(validate('abc')).to eq 'abc'
        expect { validate('abcd') }.to raise_error(OpenAPIParser::MoreThanMaxLength)
      end
    end

    context 'with oneOf' do
      let(:target) { { '$ref' => '#/components/schemas/Name', 'oneOf' => [{ 'maxLength' => 3 }] } }

      it 'checks it' do
        expect(validate('abc')).to eq 'abc'
        expect { validate('abcd') }.to raise_error(OpenAPIParser::NotOneOf)
      end
    end
  end

  context 'with a 3.0 document' do
    let(:openapi_version) { '3.0.3' }
    let(:target) { { '$ref' => '#/components/schemas/Name', 'maxLength' => 3 } }

    it 'ignores the keyword' do
      expect(validate('abcd')).to eq 'abcd'
    end

    it 'is the referenced schema' do
      expect(schema).to be root.components.schemas['Name']
    end
  end

  context 'when it is not a Schema Object' do
    let(:target) { { 'type' => 'string' } }
    let(:paths) do
      {
        '/a' => {
          'get' => {
            'parameters' => [{ '$ref' => '#/components/parameters/P', 'required' => true }],
            'responses' => { '200' => { 'description' => 'ok' } },
          },
        },
      }
    end
    let(:root) do
      raw = {
        'openapi' => openapi_version,
        'info' => { 'title' => 'test', 'version' => '1.0' },
        'paths' => paths,
        'components' => { 'parameters' => { 'P' => { 'name' => 'p', 'in' => 'query', 'schema' => target } } },
      }
      OpenAPIParser.parse(raw, strict_reference_validation: true)
    end

    it 'ignores the keyword next to $ref' do
      parameter = root.paths.path['/a'].get.parameters.first
      expect(parameter).to be root.components.parameters['P']
      expect(parameter.required).to be_nil
    end
  end

  context 'with coerce_value' do
    context 'when the referenced schema has type' do
      let(:target) { { '$ref' => '#/components/schemas/Count', 'maximum' => 5 } }

      it 'checks the keyword with the coerced value' do
        expect { validate('9', coerce_options) }.to raise_error(OpenAPIParser::MoreThanMaximum)
      end

      it 'returns the coerced value' do
        expect(validate('3', coerce_options)).to eq 3
      end
    end

    context 'when type is next to a $ref without type' do
      let(:base_schemas) { { 'Small' => { 'maximum' => 5 } } }
      let(:target) { { '$ref' => '#/components/schemas/Small', 'type' => 'integer' } }

      it 'coerces the value first' do
        expect(validate('3', coerce_options)).to eq 3
        expect { validate('9', coerce_options) }.to raise_error(OpenAPIParser::MoreThanMaximum)
      end
    end

    context 'when a date-time is coerced' do
      let(:base_schemas) { { 'Time' => { 'type' => 'string', 'format' => 'date-time' } } }
      let(:target) { { '$ref' => '#/components/schemas/Time', 'maxLength' => 20 } }
      let(:date_time_options) { ::OpenAPIParser::SchemaValidator::Options.new(coerce_value: true, datetime_coerce_class: DateTime) }

      it 'returns the DateTime' do
        expect(validate('2026-11-05T00:00:00Z', date_time_options)).to be_a(DateTime)
      end

      it 'checks the keyword with the original string' do
        expect { validate('2026-11-05T00:00:00+09:00', date_time_options) }.to raise_error(OpenAPIParser::MoreThanMaxLength)
      end
    end
  end

  context 'when the reference cannot be resolved' do
    let(:target) { { '$ref' => '#/components/schemas/Missing', 'maxLength' => 3 } }

    it 'raises an error with strict_reference_validation' do
      expect { schema }.to raise_error(OpenAPIParser::MissingReferenceError)
    end

    context 'without strict_reference_validation' do
      let(:strict_reference_validation) { false }

      it 'checks only the keyword' do
        expect(validate('abc')).to eq 'abc'
        expect { validate('abcd') }.to raise_error(OpenAPIParser::MoreThanMaxLength)
      end
    end
  end

  context 'when $ref points into the keywords next to $ref' do
    let(:base_schemas) do
      {
        'Name' => { 'type' => 'string' },
        'Holder' => { '$ref' => '#/components/schemas/Name', 'properties' => { 'x' => { 'type' => 'integer' } } },
      }
    end
    let(:target) { { '$ref' => '#/components/schemas/Holder/properties/x' } }

    it 'resolves the reference' do
      expect(schema.type).to eq 'integer'
    end
  end

  context 'with SpecValidator' do
    let(:target) { { '$ref' => '#/components/schemas/Name', 'nullable' => true } }

    it 'reports a keyword next to $ref once' do
      violations = OpenAPIParser::SpecValidator::Rules::NullableDeprecation.new(root.openapi_version).check(root)
      expect(violations.map(&:path)).to eq ['#/components/schemas/Target']
    end
  end
end

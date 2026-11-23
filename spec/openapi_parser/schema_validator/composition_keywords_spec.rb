require_relative '../../spec_helper'

RSpec.describe 'keywords next to allOf, anyOf and oneOf' do
  let(:openapi_version) { '3.1.0' }
  let(:options) { ::OpenAPIParser::SchemaValidator::Options.new }
  let(:coerce_options) { ::OpenAPIParser::SchemaValidator::Options.new(coerce_value: true) }
  let(:document) do
    {
      'openapi' => openapi_version,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => schemas },
    }
  end
  let(:root) { OpenAPIParser.parse(document, strict_reference_validation: true) }
  let(:schema) { root.components.schemas['Target'] }

  def validate(value, validate_options = options)
    OpenAPIParser::SchemaValidator.validate(value, schema, validate_options)
  end

  context 'when a keyword is next to allOf' do
    let(:schemas) { { 'Target' => { 'allOf' => [{ 'type' => 'string' }], 'maxLength' => 3 } } }

    it 'rejects a value that breaks the keyword' do
      expect { validate('abcd') }.to raise_error(OpenAPIParser::MoreThanMaxLength)
    end

    it 'accepts a value that satisfies both' do
      expect(validate('abc')).to eq 'abc'
    end

    it 'rejects a value that breaks allOf' do
      expect { validate(1) }.to raise_error(OpenAPIParser::ValidateError)
    end
  end

  context 'when an allOf member has a discriminator' do
    let(:openapi_version) { '3.1.1' }
    let(:schema) { root.components.schemas['Pet'] }
    let(:schemas) do
      {
        'Pet' => {
          'type' => 'object',
          'properties' => { 'petType' => { 'type' => 'string' } },
          'required' => ['petType'],
          'discriminator' => { 'propertyName' => 'petType' },
        },
        'Dog' => {
          'allOf' => [
            { '$ref' => '#/components/schemas/Pet' },
            {
              'type' => 'object',
              'properties' => { 'bark' => { 'type' => 'string' } },
              'required' => ['bark'],
            },
          ],
        },
      }
    end

    where(:openapi_version) { ['3.0.4', '3.1.1', '3.2.1'] }

    with_them do
      it 'accepts a value that satisfies the parent schema' do
        value = { 'petType' => 'Dog' }
        expect(validate(value)).to eq value
      end
    end

    it 'checks required properties on the parent' do
      expect { validate({}) }.to raise_error(OpenAPIParser::NotExistRequiredKey, /Pet missing required parameters: petType/)
    end

    context 'when validating the child directly' do
      let(:schema) { root.components.schemas['Dog'] }

      it 'requires the properties from the child' do
        expect { validate({ 'petType' => 'Dog' }) }.to raise_error(OpenAPIParser::NotExistRequiredKey, /Dog\/allOf\/1 missing required parameters: bark/)
      end
    end

    context 'in a 3.0.3 document' do
      let(:openapi_version) { '3.0.3' }

      it 'retains discriminator dispatch to the child' do
        expect { validate({ 'petType' => 'Dog' }) }.to raise_error(OpenAPIParser::NotExistRequiredKey, /Dog\/allOf\/1 missing required parameters: bark/)
      end
    end
  end

  context 'when a keyword is next to anyOf' do
    let(:schemas) { { 'Target' => { 'anyOf' => [{ 'type' => 'string' }], 'maxLength' => 3 } } }

    it 'rejects a value that breaks the keyword' do
      expect { validate('abcd') }.to raise_error(OpenAPIParser::MoreThanMaxLength)
    end

    it 'accepts a value that satisfies both' do
      expect(validate('abc')).to eq 'abc'
    end
  end

  context 'when a keyword is next to oneOf' do
    let(:schemas) { { 'Target' => { 'oneOf' => [{ 'type' => 'string' }], 'maxLength' => 3 } } }

    it 'rejects a value that breaks the keyword' do
      expect { validate('abcd') }.to raise_error(OpenAPIParser::MoreThanMaxLength)
    end

    it 'accepts a value that satisfies both' do
      expect(validate('abc')).to eq 'abc'
    end
  end

  context 'when type and required are next to a composition keyword' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'required' => ['c'],
          'oneOf' => [{ 'required' => ['a'] }, { 'required' => ['b'] }],
        },
      }
    end

    it 'rejects an object without the required property' do
      expect { validate({ 'a' => 1 }) }.to raise_error(OpenAPIParser::NotExistRequiredKey)
    end

    it 'rejects a value of another type' do
      expect { validate(1) }.to raise_error(OpenAPIParser::ValidateError)
    end
  end

  context 'when two composition keywords are in one schema' do
    context 'with allOf and oneOf' do
      let(:schemas) { { 'Target' => { 'allOf' => [{ 'type' => 'string' }], 'oneOf' => [{ 'maxLength' => 1 }, { 'minLength' => 3 }] } } }

      it 'checks both' do
        expect(validate('abc')).to eq 'abc'
        expect { validate('ab') }.to raise_error(OpenAPIParser::NotOneOf)
        expect { validate(1) }.to raise_error(OpenAPIParser::ValidateError)
      end
    end

    context 'with anyOf and allOf' do
      let(:schemas) { { 'Target' => { 'anyOf' => [{ 'type' => 'string' }], 'allOf' => [{ 'maxLength' => 3 }] } } }

      it 'checks both' do
        expect(validate('abc')).to eq 'abc'
        expect { validate('abcd') }.to raise_error(OpenAPIParser::MoreThanMaxLength)
      end
    end

    context 'with anyOf and oneOf' do
      let(:schemas) { { 'Target' => { 'anyOf' => [{ 'type' => 'string' }], 'oneOf' => [{ 'maxLength' => 3 }] } } }

      it 'checks both' do
        expect(validate('abc')).to eq 'abc'
        expect { validate('abcd') }.to raise_error(OpenAPIParser::NotOneOf)
      end
    end
  end

  context 'when properties are next to allOf' do
    let(:schemas) do
      {
        'Target' => {
          'allOf' => [{ 'type' => 'object', 'properties' => { 'a' => { 'type' => 'integer' } } }],
          'properties' => { 'b' => { 'type' => 'integer' } },
        },
      }
    end

    it 'checks the properties' do
      expect { validate({ 'a' => 1, 'b' => 'x' }) }.to raise_error(OpenAPIParser::ValidateError)
    end

    it 'accepts the properties of both' do
      value = { 'a' => 1, 'b' => 1 }
      expect(validate(value)).to eq value
    end
  end

  context 'when additionalProperties: false is next to allOf' do
    let(:schemas) do
      {
        'Target' => {
          'allOf' => [{ 'type' => 'object', 'properties' => { 'a' => { 'type' => 'integer' } } }],
          'properties' => { 'b' => { 'type' => 'integer' } },
          'additionalProperties' => false,
        },
      }
    end

    it 'rejects a property defined only in allOf' do
      expect { validate({ 'a' => 1 }) }.to raise_error(OpenAPIParser::NotExistPropertyDefinition)
    end

    it 'accepts a property defined next to it' do
      value = { 'b' => 1 }
      expect(validate(value)).to eq value
    end
  end

  context 'when the schema is a member of allOf' do
    let(:schemas) { { 'Target' => { 'allOf' => [{ 'oneOf' => [{ 'type' => 'string' }], 'maxLength' => 3 }] } } }

    it 'checks its keywords' do
      expect { validate('abcd') }.to raise_error(OpenAPIParser::MoreThanMaxLength)
    end
  end

  context 'when discriminator is next to oneOf or anyOf' do
    let(:openapi_version) { '3.1.1' }
    let(:composition) { 'oneOf' }
    let(:cat_required) { ['petType'] }
    let(:dog_required) { ['petType'] }
    let(:properties) do
      { 'petType' => { 'type' => 'string' }, 'meow' => { 'type' => 'string' }, 'bark' => { 'type' => 'string' } }
    end
    let(:schemas) do
      {
        'Cat' => { 'type' => 'object', 'properties' => properties, 'required' => cat_required },
        'Dog' => { 'type' => 'object', 'properties' => properties, 'required' => dog_required },
        'Target' => {
          composition => [{ '$ref' => '#/components/schemas/Cat' }, { '$ref' => '#/components/schemas/Dog' }],
          'discriminator' => { 'propertyName' => 'petType' },
        },
      }
    end

    where(:openapi_version) { ['3.1.1', '3.2.0'] }

    with_them do
      it 'rejects oneOf when both members match' do
        expect { validate({ 'petType' => 'Cat' }) }.to raise_error(OpenAPIParser::NotOneOf)
      end
    end

    context 'when the member named by the discriminator fails' do
      let(:cat_required) { %w[petType meow] }

      where(:composition) { ['oneOf', 'anyOf'] }

      with_them do
        it 'accepts the value when another member matches' do
          value = { 'petType' => 'Cat' }
          expect(validate(value)).to eq value
        end

        context 'when no member matches' do
          let(:dog_required) { %w[petType bark] }

          it 'reports the error from the named member' do
            expect { validate({ 'petType' => 'Dog' }) }
              .to raise_error(OpenAPIParser::NotExistRequiredKey, /Dog missing required parameters: bark/)
          end
        end
      end
    end

    context 'in a 3.0 document' do
      let(:openapi_version) { '3.0.3' }

      it 'retains the discriminator shortcut' do
        value = { 'petType' => 'Cat' }
        expect(validate(value)).to eq value
      end
    end

    it 'reports the mapped member error from an already loaded document' do
      reference = 'normal.yml#/components/schemas/all_of_base'
      schemas['Target']['oneOf'] = [{ '$ref' => reference }]
      schemas['Target']['discriminator']['mapping'] = { 'Cat' => reference }
      parsed = OpenAPIParser.parse_with_filepath(document, 'spec/data/discriminator.yml', strict_reference_validation: true)
      expect do
        OpenAPIParser::SchemaValidator.validate({ 'petType' => 'Cat' }, parsed.components.schemas['Target'], options)
      end.to raise_error(OpenAPIParser::NotExistRequiredKey, /all_of_base missing required parameters: name/)
    end
  end

  context 'when discriminator is next to oneOf with other keywords' do
    let(:schemas) do
      {
        'Cat' => { 'type' => 'object', 'required' => ['lives'], 'properties' => { 'kind' => { 'type' => 'string' }, 'lives' => { 'type' => 'integer' } } },
        'Dog' => { 'type' => 'object', 'required' => ['bark'], 'properties' => { 'kind' => { 'type' => 'string' }, 'bark' => { 'type' => 'boolean' } } },
        'Target' => {
          'type' => 'object',
          'required' => ['name'],
          'oneOf' => [{ '$ref' => '#/components/schemas/Cat' }, { '$ref' => '#/components/schemas/Dog' }],
          'discriminator' => { 'propertyName' => 'kind' },
        },
      }
    end

    it 'uses the discriminator to select the error' do
      expect { validate({ 'kind' => 'Cat', 'name' => 'a', 'lives' => 'x' }) }
        .to raise_error(OpenAPIParser::ValidateError, %r{Cat/properties/lives})
    end

    it 'accepts the value when exactly one member matches' do
      value = { 'kind' => 'Cat', 'name' => 'a', 'lives' => 9 }
      expect(validate(value)).to eq value
    end

    it 'checks the other keywords' do
      expect { validate({ 'kind' => 'Cat', 'lives' => 9 }) }.to raise_error(OpenAPIParser::NotExistRequiredKey)
    end
  end

  context 'when nullable is next to a composition keyword' do
    let(:openapi_version) { '3.0.3' }
    let(:schemas) do
      {
        'Nullable' => { 'nullable' => true, 'oneOf' => [{ 'type' => 'string' }] },
        'NotNullable' => { 'type' => 'string', 'oneOf' => [{ 'maxLength' => 3 }] },
        'Target' => { 'type' => 'object', 'properties' => { 'a' => { '$ref' => '#/components/schemas/Nullable' }, 'b' => { '$ref' => '#/components/schemas/NotNullable' } } },
      }
    end

    it 'accepts null' do
      value = { 'a' => nil }
      expect(validate(value)).to eq value
    end

    it 'rejects null when type does not allow it' do
      expect { validate({ 'b' => nil }) }.to raise_error(OpenAPIParser::NotNullError)
    end
  end

  context 'with a 3.0 document' do
    let(:openapi_version) { '3.0.3' }
    let(:schemas) { { 'Target' => { 'allOf' => [{ 'type' => 'string' }], 'maxLength' => 3 } } }

    it 'checks the keyword in the same way' do
      expect { validate('abcd') }.to raise_error(OpenAPIParser::MoreThanMaxLength)
    end
  end

  context 'with coerce_value' do
    context 'when allOf has a member with type' do
      let(:schemas) { { 'Target' => { 'allOf' => [{ 'maximum' => 5 }, { 'type' => 'integer' }] } } }

      it 'returns the coerced value' do
        expect(validate('3', coerce_options)).to eq 3
      end

      it 'checks a member without type that comes before it' do
        expect { validate('9', coerce_options) }.to raise_error(OpenAPIParser::MoreThanMaximum)
      end
    end

    context 'when oneOf has a member with type' do
      let(:schemas) { { 'Target' => { 'oneOf' => [{ 'type' => 'integer' }, { 'type' => 'boolean' }] } } }

      it 'returns the coerced value' do
        expect(validate('3', coerce_options)).to eq 3
      end
    end

    context 'when a keyword is next to a composition keyword with type' do
      let(:schemas) { { 'Target' => { 'oneOf' => [{ 'type' => 'integer' }], 'maximum' => 5 } } }

      it 'checks the keyword with the coerced value' do
        expect { validate('9', coerce_options) }.to raise_error(OpenAPIParser::MoreThanMaximum)
      end

      it 'returns the coerced value' do
        expect(validate('3', coerce_options)).to eq 3
      end
    end

    context 'when type is next to a composition keyword without type' do
      let(:schemas) do
        {
          'Integer' => { 'type' => 'integer', 'allOf' => [{ 'maximum' => 5 }] },
          'Boolean' => { 'type' => 'boolean', 'oneOf' => [{ 'enum' => [true] }] },
          'Target' => { 'type' => 'object', 'properties' => { 'i' => { '$ref' => '#/components/schemas/Integer' }, 'b' => { '$ref' => '#/components/schemas/Boolean' } } },
        }
      end

      it 'checks the composition keyword with the coerced value' do
        expect { validate({ 'i' => '9' }, coerce_options) }.to raise_error(OpenAPIParser::MoreThanMaximum)
      end

      it 'compares enum with the coerced value' do
        expect(validate({ 'b' => 'true' }, coerce_options)).to eq({ 'b' => true })
      end
    end

    context 'when an object is coerced' do
      let(:schemas) do
        {
          'Target' => {
            'allOf' => [{ 'type' => 'object', 'properties' => { 'n' => { 'type' => 'integer' } } }],
            'properties' => { 'n' => { 'maximum' => 5 } },
          },
        }
      end

      it 'coerces the property' do
        expect(validate({ 'n' => '3' }, coerce_options)).to eq({ 'n' => 3 })
      end

      it 'checks a keyword next to it with the coerced property' do
        expect { validate({ 'n' => '9' }, coerce_options) }.to raise_error(OpenAPIParser::MoreThanMaximum)
      end
    end

    context 'when a date-time is coerced' do
      let(:date_time_options) { ::OpenAPIParser::SchemaValidator::Options.new(coerce_value: true, datetime_coerce_class: DateTime) }
      let(:date_time) { { 'type' => 'string', 'format' => 'date-time' } }
      let(:schemas) do
        {
          'Next' => { 'allOf' => [date_time], 'maxLength' => 20 },
          'Member' => { 'allOf' => [date_time, { 'type' => 'string', 'maxLength' => 20 }] },
          'Target' => { 'type' => 'object', 'properties' => { 'next' => { '$ref' => '#/components/schemas/Next' }, 'member' => { '$ref' => '#/components/schemas/Member' } } },
        }
      end

      it 'returns the DateTime' do
        expect(validate({ 'next' => '2026-11-05T00:00:00Z' }, date_time_options)['next']).to be_a(DateTime)
        expect(validate({ 'member' => '2026-11-05T00:00:00Z' }, date_time_options)['member']).to be_a(DateTime)
      end

      it 'checks a keyword next to it with the original string' do
        expect { validate({ 'next' => '2026-11-05T00:00:00+09:00' }, date_time_options) }.to raise_error(OpenAPIParser::MoreThanMaxLength)
      end

      it 'checks a member of allOf with the original string' do
        expect { validate({ 'member' => '2026-11-05T00:00:00+09:00' }, date_time_options) }.to raise_error(OpenAPIParser::MoreThanMaxLength)
      end
    end
  end
end

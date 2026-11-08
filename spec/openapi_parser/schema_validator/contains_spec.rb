require_relative '../../spec_helper'

RSpec.describe 'contains, minContains and maxContains keywords' do
  let(:options) { ::OpenAPIParser::SchemaValidator::Options.new }
  let(:openapi_version) { '3.1.0' }
  let(:root) do
    raw = {
      'openapi' => openapi_version,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => schemas },
    }
    OpenAPIParser.parse(raw, strict_reference_validation: true)
  end
  let(:schema) { root.components.schemas['Target'] }

  def validate(value)
    OpenAPIParser::SchemaValidator.validate(value, schema, options)
  end

  context 'when the array must contain a matching item' do
    let(:schemas) { { 'Target' => { 'type' => 'array', 'contains' => { 'type' => 'integer' } } } }

    it 'rejects an array without a matching item' do
      expect { validate(%w[a b]) }.to raise_error(
        OpenAPIParser::LessThanMinContains,
        %r{#/components/schemas/Target \["a", "b"\] contains fewer than minContains matching items},
      )
    end

    it 'accepts an array with one matching item' do
      value = ['a', 1, 'b']
      expect(validate(value)).to eq value
    end

    it 'accepts an array whose items all match' do
      expect(validate([1, 2, 3])).to eq [1, 2, 3]
    end

    it 'rejects an empty array' do
      expect { validate([]) }.to raise_error(OpenAPIParser::LessThanMinContains)
    end
  end

  context 'with minContains' do
    let(:schemas) { { 'Target' => { 'type' => 'array', 'contains' => { 'type' => 'integer' }, 'minContains' => 2 } } }

    it 'rejects an array with fewer matching items' do
      expect { validate(['a', 1]) }.to raise_error(OpenAPIParser::LessThanMinContains)
    end

    it 'accepts an array with enough matching items' do
      value = [1, 'a', 2]
      expect(validate(value)).to eq value
    end
  end

  context 'with maxContains' do
    let(:schemas) { { 'Target' => { 'type' => 'array', 'contains' => { 'type' => 'integer' }, 'maxContains' => 2 } } }

    it 'rejects an array with more matching items' do
      expect { validate([1, 2, 3]) }.to raise_error(
        OpenAPIParser::MoreThanMaxContains,
        %r{#/components/schemas/Target \[1, 2, 3\] contains more than maxContains matching items},
      )
    end

    it 'accepts an array with up to that many matching items' do
      value = [1, 'a', 2]
      expect(validate(value)).to eq value
    end

    it 'still needs one matching item' do
      expect { validate(['a']) }.to raise_error(OpenAPIParser::LessThanMinContains)
    end
  end

  context 'with both minContains and maxContains' do
    let(:schemas) do
      { 'Target' => { 'type' => 'array', 'contains' => { 'type' => 'integer' }, 'minContains' => 2, 'maxContains' => 3 } }
    end

    it 'accepts a number of matching items in the range' do
      expect(validate([1, 2])).to eq [1, 2]
      expect(validate([1, 2, 3, 'a'])).to eq [1, 2, 3, 'a']
    end

    it 'rejects fewer matching items' do
      expect { validate([1, 'a']) }.to raise_error(OpenAPIParser::LessThanMinContains)
    end

    it 'rejects more matching items' do
      expect { validate([1, 2, 3, 4]) }.to raise_error(OpenAPIParser::MoreThanMaxContains)
    end
  end

  context 'with items' do
    let(:schemas) do
      { 'Target' => { 'type' => 'array', 'items' => { 'type' => 'integer' }, 'contains' => { 'type' => 'integer', 'minimum' => 5 } } }
    end

    it 'checks both keywords' do
      expect(validate([1, 5])).to eq [1, 5]
      expect { validate([1, 2]) }.to raise_error(OpenAPIParser::LessThanMinContains)
      expect { validate([5, 'a']) }.to raise_error(OpenAPIParser::ValidateError)
    end

    context 'when coerce_value is on' do
      let(:options) { ::OpenAPIParser::SchemaValidator::Options.new(coerce_value: true) }
      let(:schemas) do
        {
          'Target' => {
            'type' => 'array',
            'items' => { 'type' => 'string' },
            'contains' => { 'type' => 'integer' },
          },
        }
      end

      it 'coerces the items by items, not by contains' do
        expect(validate(%w[1 a])).to eq %w[1 a]
      end
    end
  end

  context 'when minContains is 0' do
    let(:schemas) do
      { 'Target' => { 'type' => 'array', 'contains' => { 'type' => 'integer' }, 'minContains' => 0, 'maxContains' => 1 } }
    end

    it 'accepts an array without a matching item' do
      expect(validate(%w[a b])).to eq %w[a b]
    end

    it 'accepts an empty array' do
      expect(validate([])).to eq []
    end

    it 'still checks maxContains' do
      expect { validate([1, 2]) }.to raise_error(OpenAPIParser::MoreThanMaxContains)
    end
  end

  context 'when the schema has no type' do
    let(:schemas) { { 'Target' => { 'contains' => { 'type' => 'integer' } } } }

    it 'checks an array' do
      expect { validate(['a']) }.to raise_error(OpenAPIParser::LessThanMinContains)
    end

    it 'ignores a value that is not an array' do
      expect(validate({ 'a' => 'b' })).to eq({ 'a' => 'b' })
    end
  end

  context 'when the keyword is in a nested schema' do
    let(:schemas) do
      {
        'Target' => {
          'type' => 'object',
          'properties' => { 'nested' => { 'type' => 'array', 'contains' => { '$ref' => '#/components/schemas/Int' } } },
        },
        'Int' => { 'type' => 'integer' },
      }
    end

    it 'checks the keyword' do
      expect { validate({ 'nested' => ['a'] }) }.to raise_error(
        OpenAPIParser::LessThanMinContains,
        %r{#/components/schemas/Target/properties/nested \["a"\] contains fewer than minContains matching items},
      )
      expect(validate({ 'nested' => [1] })).to eq({ 'nested' => [1] })
    end
  end

  context 'when contains is a boolean schema' do
    context 'with true' do
      let(:schemas) { { 'Target' => { 'type' => 'array', 'contains' => true, 'maxContains' => 2 } } }

      it 'counts every item for true' do
        expect(validate(['a', 1])).to eq ['a', 1]
        expect { validate([]) }.to raise_error(OpenAPIParser::LessThanMinContains)
        expect { validate(['a', 1, nil]) }.to raise_error(OpenAPIParser::MoreThanMaxContains)
      end
    end

    context 'with false' do
      let(:schemas) { { 'Target' => { 'type' => 'array', 'contains' => false } } }

      it 'counts no item for false' do
        expect { validate(['a', 1]) }.to raise_error(OpenAPIParser::LessThanMinContains)
      end
    end
  end

  context 'with a 3.0 document' do
    let(:openapi_version) { '3.0.3' }
    let(:schemas) { { 'Target' => { 'type' => 'array', 'contains' => { 'type' => 'integer' }, 'maxContains' => 1 } } }

    it 'checks the keywords in the same way' do
      expect { validate(['a']) }.to raise_error(OpenAPIParser::LessThanMinContains)
      expect { validate([1, 2]) }.to raise_error(OpenAPIParser::MoreThanMaxContains)
    end
  end

  context 'when minContains or maxContains is used without contains' do
    let(:schemas) { { 'Target' => { 'type' => 'array', 'minContains' => 2, 'maxContains' => 0 } } }

    it 'ignores them' do
      expect(validate(['a'])).to eq ['a']
    end
  end

  context 'when minContains or maxContains is a decimal with no fractional part' do
    let(:schemas) do
      { 'Target' => { 'type' => 'array', 'contains' => { 'type' => 'integer' }, 'minContains' => 2.0, 'maxContains' => 2.0 } }
    end

    it 'treats it as an integer' do
      expect { validate([1]) }.to raise_error(OpenAPIParser::LessThanMinContains)
      expect(validate([1, 2])).to eq [1, 2]
      expect { validate([1, 2, 3]) }.to raise_error(OpenAPIParser::MoreThanMaxContains)
    end
  end

  context 'when minContains or maxContains is not a non-negative integer' do
    let(:schemas) do
      { 'Target' => { 'type' => 'array', 'contains' => { 'type' => 'integer' }, 'minContains' => -1, 'maxContains' => 'one' } }
    end

    it 'treats minContains as 1' do
      expect { validate(['a']) }.to raise_error(OpenAPIParser::LessThanMinContains)
    end

    it 'ignores maxContains' do
      expect(validate([1, 2])).to eq [1, 2]
    end
  end
end

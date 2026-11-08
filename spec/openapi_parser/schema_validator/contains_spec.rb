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

    it 'accepts an array with one matching item'
    it 'accepts an array whose items all match'
    it 'rejects an empty array'
  end

  context 'with minContains' do
    it 'rejects an array with fewer matching items'
    it 'accepts an array with enough matching items'
  end

  context 'with maxContains' do
    it 'rejects an array with more matching items'
    it 'accepts an array with up to that many matching items'
    it 'still needs one matching item'
  end

  context 'with both minContains and maxContains' do
    it 'accepts a number of matching items in the range'
    it 'rejects fewer matching items'
    it 'rejects more matching items'
  end

  context 'with items' do
    it 'checks both keywords'
    it 'coerces the items by items, not by contains'
  end

  context 'when minContains is 0' do
    it 'accepts an array without a matching item'
    it 'accepts an empty array'
    it 'still checks maxContains'
  end

  context 'when the schema has no type' do
    it 'checks an array'
    it 'ignores a value that is not an array'
  end

  context 'when the keyword is in a nested schema' do
    it 'checks the keyword'
  end

  context 'when contains is a boolean schema' do
    it 'counts every item for true'
    it 'counts no item for false'
  end

  context 'with a 3.0 document' do
    it 'checks the keywords in the same way'
  end

  context 'when minContains or maxContains is used without contains' do
    it 'ignores them'
  end

  context 'when minContains or maxContains is a decimal with no fractional part' do
    it 'treats it as an integer'
  end

  context 'when minContains or maxContains is not a non-negative integer' do
    it 'treats minContains as 1'
    it 'ignores maxContains'
  end
end

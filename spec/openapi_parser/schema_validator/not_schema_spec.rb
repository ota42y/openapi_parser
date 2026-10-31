require_relative '../../spec_helper'

RSpec.describe 'not keyword' do
  context 'when not forbids a property' do
    it 'rejects an object with the property'

    it 'accepts an object without the property'
  end

  context 'when not excludes a type' do
    it 'rejects a value of the type'

    it 'accepts a value of another type'
  end

  context 'when not excludes an enum value' do
    it 'rejects the value'

    it 'accepts another value'
  end

  context 'when not refers to another schema with $ref' do
    it 'rejects a value valid against the referenced schema'
  end

  context 'when not is an empty schema' do
    it 'rejects any value'
  end

  context 'when the document is OpenAPI 3.0' do
    it 'rejects a value valid against the not schema'
  end

  context 'when reading the parsed schema' do
    it 'returns the not schema as a Schema'
  end
end

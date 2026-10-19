require_relative '../../spec_helper'

RSpec.describe 'boolean schema (3.1)' do
  context 'when items is false after prefixItems' do
    it 'accepts an array that matches the prefix'
    it 'rejects an element past the prefix'
  end

  context 'when a property schema is false' do
    it 'rejects the property'
    it 'accepts an object without the property'
  end

  context 'when a property schema is true' do
    it 'accepts any value for the property'
    it 'accepts null for the property'
  end

  context 'when a $ref points to a boolean schema' do
    it 'validates with the referenced boolean schema'
  end

  context 'when the request body schema itself is false' do
    it 'rejects any body'
  end

  context 'when reading the parsed schema' do
    it 'returns a Schema whose raw_schema is the boolean'
  end
end

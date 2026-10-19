require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::BooleanSchemaIn30' do
  context 'with a 3.1 document using a boolean schema' do
    it 'reports no violation'
  end

  context 'with a 3.1 document without a boolean schema' do
    it 'reports no violation'
  end

  context 'with a 3.0 document using a boolean schema' do
    it 'reports one violation pointing at the offending schema'
  end

  context 'with a 3.0 document without a boolean schema' do
    it 'reports no violation'
  end

  context 'with a 3.0 document using additionalProperties: false' do
    it 'reports no violation'
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)'
  end
end

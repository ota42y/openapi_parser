require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::ContainsIn30' do
  context 'with a 3.1 document using contains' do
    it 'reports no violation'
  end

  context 'with a 3.1 document without contains' do
    it 'reports no violation'
  end

  context 'with a 3.0 document using contains' do
    it 'reports one violation pointing at the offending schema'
  end

  context 'with a 3.0 document using minContains or maxContains' do
    it 'reports one violation per schema'
  end

  context 'with a 3.0 document without contains' do
    it 'reports no violation'
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)'
  end
end

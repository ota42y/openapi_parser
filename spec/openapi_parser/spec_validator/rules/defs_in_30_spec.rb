require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::DefsIn30' do
  context 'with a 3.1 document using $defs' do
    it 'reports no violation'
  end

  context 'with a 3.1 document without $defs' do
    it 'reports no violation'
  end

  context 'with a 3.0 document using $defs' do
    it 'reports one violation pointing at the offending schema'
  end

  context 'with a 3.0 document without $defs' do
    it 'reports no violation'
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)'
  end
end

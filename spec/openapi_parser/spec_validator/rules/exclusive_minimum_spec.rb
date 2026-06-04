require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::ExclusiveMinimum' do
  context 'with a 3.0 document using a 3.0-style boolean exclusiveMinimum' do
    it 'reports no violation'
  end

  context 'with a 3.1 document using a 3.1-style numeric exclusiveMinimum' do
    it 'reports no violation'
  end

  context 'with a 3.0 document using a 3.1-style numeric exclusiveMinimum' do
    it 'reports one violation pointing at the offending schema'
  end

  context 'with a 3.1 document using a 3.0-style boolean exclusiveMinimum' do
    it 'reports one violation pointing at the offending schema'
  end

  context 'with an :unknown version document containing exclusiveMinimum' do
    it 'reports no violation (rule skipped)'
  end

  context 'with a schema that has no exclusiveMinimum' do
    it 'reports no violation'
  end
end

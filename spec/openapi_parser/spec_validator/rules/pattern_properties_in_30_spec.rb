require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::PatternPropertiesIn30' do
  context 'with a 3.1 document using patternProperties' do
    it 'reports no violation'
  end

  context 'with a 3.1 document without patternProperties' do
    it 'reports no violation'
  end

  context 'with a 3.0 document using patternProperties' do
    it 'reports one violation pointing at the offending schema'
  end

  context 'with a 3.0 document without patternProperties' do
    it 'reports no violation'
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)'
  end
end

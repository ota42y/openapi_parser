require_relative '../../spec_helper'

RSpec.describe 'OpenAPIParser 3.1 spec validator (integration)' do
  describe 'strict_specification_version :silent (default)' do
    it 'never warns or raises even when the document contains violations'
  end

  describe 'exclusiveMinimum (3.0 Boolean modifier vs 3.1 numeric bound)' do
    it 'warns on the version-mismatched document under :warn'

    it 'raises SpecViolationError on the version-mismatched document under :raise'

    it 'stays clean on the correctly-versioned document'
  end
end

require_relative '../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator' do
  describe '.run' do
    context 'with a root that has no spec-version-specific issues' do
      it 'returns an empty array'
    end

    context 'with a root whose openapi field is unrecognized' do
      it 'returns an empty array (version-specific rules are skipped)'
    end

    context 'with violations detected by a registered rule' do
      it 'returns the collected SpecViolation list'
    end
  end

  describe '.run!' do
    context 'with policy :silent' do
      it 'returns nil without running validation'
    end

    context 'with policy :warn and violations present' do
      it 'emits one warning per violation to stderr'
    end

    context 'with policy :warn and no violations' do
      it 'produces no output'
    end

    context 'with policy :raise and violations present' do
      it 'raises SpecViolationError carrying the violations'
    end

    context 'with policy :raise and no violations' do
      it 'does not raise'
    end
  end
end

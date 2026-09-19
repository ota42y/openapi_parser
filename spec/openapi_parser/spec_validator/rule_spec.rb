require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::SpecValidator::Rule do
  def rule_for(version_string)
    version = version_string && Gem::Version.new(version_string)
    OpenAPIParser::SpecValidator::Rule.new(version)
  end

  describe '#version_before?' do
    context 'with a 3.0.0 document and a 3.1 boundary' do
      it 'returns true'
    end

    context 'with a 3.1.0 document and a 3.1 boundary' do
      it 'returns false (the boundary itself is not before)'
    end

    context 'with a 3.2.0 document and a 3.1 boundary' do
      it 'returns false'
    end

    context 'with a 3.0.3 patch version and a 3.1 boundary' do
      it 'returns true'
    end

    context 'with an unknown (nil) version' do
      it 'returns false'
    end
  end

  describe '#version_at_least?' do
    context 'with a 3.1.0 document and a 3.1 boundary' do
      it 'returns true (the boundary itself counts)'
    end

    context 'with a 3.2.0 document and a 3.1 boundary' do
      it 'returns true'
    end

    context 'with a 3.0.0 document and a 3.1 boundary' do
      it 'returns false'
    end

    context 'with an unknown (nil) version' do
      it 'returns false'
    end
  end
end

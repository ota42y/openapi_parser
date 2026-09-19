require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::SpecValidator::Rule do
  def rule_for(version_string)
    version = version_string && Gem::Version.new(version_string)
    OpenAPIParser::SpecValidator::Rule.new(version)
  end

  describe '#version_before?' do
    context 'with a 3.0.0 document and a 3.1 boundary' do
      it 'returns true' do
        expect(rule_for('3.0.0').version_before?('3.1')).to be true
      end
    end

    context 'with a 3.1.0 document and a 3.1 boundary' do
      it 'returns false (the boundary itself is not before)' do
        expect(rule_for('3.1.0').version_before?('3.1')).to be false
      end
    end

    context 'with a 3.2.0 document and a 3.1 boundary' do
      it 'returns false' do
        expect(rule_for('3.2.0').version_before?('3.1')).to be false
      end
    end

    context 'with a 3.0.3 patch version and a 3.1 boundary' do
      it 'returns true' do
        expect(rule_for('3.0.3').version_before?('3.1')).to be true
      end
    end

    context 'with an unknown (nil) version' do
      it 'returns false' do
        expect(rule_for(nil).version_before?('3.1')).to be false
      end
    end
  end

  describe '#version_at_least?' do
    context 'with a 3.1.0 document and a 3.1 boundary' do
      it 'returns true (the boundary itself counts)' do
        expect(rule_for('3.1.0').version_at_least?('3.1')).to be true
      end
    end

    context 'with a 3.2.0 document and a 3.1 boundary' do
      it 'returns true' do
        expect(rule_for('3.2.0').version_at_least?('3.1')).to be true
      end
    end

    context 'with a 3.0.0 document and a 3.1 boundary' do
      it 'returns false' do
        expect(rule_for('3.0.0').version_at_least?('3.1')).to be false
      end
    end

    context 'with an unknown (nil) version' do
      it 'returns false' do
        expect(rule_for(nil).version_at_least?('3.1')).to be false
      end
    end
  end
end

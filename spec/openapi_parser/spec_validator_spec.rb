require_relative '../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator' do
  def parse_root(raw)
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def clean_root(version = '3.0.0')
    parse_root(
      'openapi' => version,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
    )
  end

  describe '.run' do
    context 'with a root that has no spec-version-specific issues' do
      it 'returns an empty array' do
        expect(OpenAPIParser::SpecValidator.run(clean_root)).to eq []
      end
    end

    context 'with a root whose openapi field is unrecognized' do
      it 'returns an empty array (version-specific rules are skipped)' do
        expect(OpenAPIParser::SpecValidator.run(clean_root('4.0.0'))).to eq []
      end
    end

    context 'with violations detected by a registered rule' do
      it 'returns the collected SpecViolation list' do
        root = parse_root(
          'openapi' => '3.0.0',
          'info' => { 'title' => 'test', 'version' => '1.0' },
          'paths' => {},
          'components' => {
            'schemas' => {
              'Sample' => { 'type' => 'integer', 'exclusiveMinimum' => 5 },
            },
          },
        )
        violations = OpenAPIParser::SpecValidator.run(root)
        expect(violations.size).to eq 1
        expect(violations.first).to be_a(OpenAPIParser::SpecViolation)
      end
    end
  end

  describe '.run!' do
    context 'with policy :silent' do
      it 'returns nil without running validation' do
        expect(OpenAPIParser::SpecValidator.run!(clean_root, policy: :silent)).to be_nil
      end
    end

    context 'with policy :warn and violations present' do
      it 'emits one warning per violation to stderr' do
        root = parse_root(
          'openapi' => '3.0.0',
          'info' => { 'title' => 'test', 'version' => '1.0' },
          'paths' => {},
          'components' => {
            'schemas' => {
              'Sample' => { 'type' => 'integer', 'exclusiveMinimum' => 5 },
            },
          },
        )
        expect { OpenAPIParser::SpecValidator.run!(root, policy: :warn) }
          .to output(/exclusive_minimum/).to_stderr
      end
    end

    context 'with policy :warn and no violations' do
      it 'produces no output' do
        expect { OpenAPIParser::SpecValidator.run!(clean_root, policy: :warn) }
          .not_to output.to_stderr
      end
    end

    context 'with policy :raise and violations present' do
      it 'raises SpecViolationError carrying the violations' do
        root = parse_root(
          'openapi' => '3.0.0',
          'info' => { 'title' => 'test', 'version' => '1.0' },
          'paths' => {},
          'components' => {
            'schemas' => {
              'Sample' => { 'type' => 'integer', 'exclusiveMinimum' => 5 },
            },
          },
        )
        expect { OpenAPIParser::SpecValidator.run!(root, policy: :raise) }
          .to raise_error(OpenAPIParser::SpecViolationError) do |e|
            expect(e.violations.size).to eq 1
          end
      end
    end

    context 'with policy :raise and no violations' do
      it 'does not raise' do
        expect { OpenAPIParser::SpecValidator.run!(clean_root, policy: :raise) }
          .not_to raise_error
      end
    end
  end
end

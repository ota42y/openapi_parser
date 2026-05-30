require_relative '../../spec_helper'

RSpec.describe 'OpenAPIParser 3.1 spec validator (integration)' do
  DATA_DIR = './spec/data/openapi_3_1'.freeze

  def load_doc(file, policy)
    OpenAPIParser.load(
      "#{DATA_DIR}/#{file}",
      strict_reference_validation: false,
      strict_specification_version: policy,
    )
  end

  def capture_stderr
    original = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original
  end

  def expect_mismatch_warns(file, rule_names)
    stderr = capture_stderr { load_doc(file, :warn) }
    rule_names.each { |rule_name| expect(stderr).to include("[#{rule_name}]") }
    expect(stderr.lines.size).to eq rule_names.size
  end

  def expect_mismatch_raises(file, rule_names)
    expect { load_doc(file, :raise) }
      .to raise_error(OpenAPIParser::SpecViolationError) do |error|
        expect(error.violations.map(&:rule_name)).to match_array(rule_names)
      end
  end

  def expect_clean(file)
    expect(OpenAPIParser::SpecValidator.run(load_doc(file, :silent))).to eq []
    expect { load_doc(file, :warn) }.not_to output.to_stderr
    expect { load_doc(file, :raise) }.not_to raise_error
  end

  describe 'strict_specification_version :silent (default)' do
    it 'never warns or raises even when the document contains violations' do
      expect { load_doc('exclusive_minimum_30.yaml', :silent) }.not_to output.to_stderr
      expect { load_doc('exclusive_minimum_30.yaml', :silent) }.not_to raise_error
    end
  end

  describe 'exclusiveMinimum (3.0 Boolean modifier vs 3.1 numeric bound)' do
    it 'warns on the version-mismatched document under :warn' do
      expect_mismatch_warns('exclusive_minimum_30.yaml', [:exclusive_minimum])
    end

    it 'raises SpecViolationError on the version-mismatched document under :raise' do
      expect_mismatch_raises('exclusive_minimum_30.yaml', [:exclusive_minimum])
    end

    it 'stays clean on the correctly-versioned document' do
      expect_clean('exclusive_minimum_31.yaml')
    end
  end

  describe 'exclusiveMaximum (3.0 Boolean modifier vs 3.1 numeric bound)' do
    it 'warns on the version-mismatched document under :warn' do
      expect_mismatch_warns('exclusive_maximum_30.yaml', [:exclusive_maximum])
    end

    it 'raises SpecViolationError on the version-mismatched document under :raise' do
      expect_mismatch_raises('exclusive_maximum_30.yaml', [:exclusive_maximum])
    end

    it 'stays clean on the correctly-versioned document' do
      expect_clean('exclusive_maximum_31.yaml')
    end
  end

  describe 'nullable (3.0 keyword removed in 3.1)' do
    it 'warns on the version-mismatched document under :warn' do
      expect_mismatch_warns('nullable_31.yaml', [:nullable_deprecation])
    end

    it 'raises SpecViolationError on the version-mismatched document under :raise' do
      expect_mismatch_raises('nullable_31.yaml', [:nullable_deprecation])
    end

    it 'stays clean on the correctly-versioned document' do
      expect_clean('nullable_30.yaml')
    end
  end
end

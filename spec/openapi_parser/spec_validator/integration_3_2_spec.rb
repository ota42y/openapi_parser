require_relative '../../spec_helper'

RSpec.describe 'OpenAPIParser 3.2 spec validator (integration)' do
  DATA_DIR_32 = './spec/data/openapi_3_2'.freeze

  def load_doc(file, policy)
    OpenAPIParser.load(
      "#{DATA_DIR_32}/#{file}",
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

  describe '$self (3.2 root-level document URI)' do
    it 'warns on the version-mismatched document under :warn' do
      expect_mismatch_warns('self_31.yaml', [:self_before32])
    end

    it 'raises SpecViolationError on the version-mismatched document under :raise' do
      expect_mismatch_raises('self_31.yaml', [:self_before32])
    end

    it 'stays clean on the correctly-versioned document' do
      expect_clean('self_32.yaml')
    end
  end

  describe 'Tag Object summary/parent/kind (3.2 additions)' do
    it 'warns on the version-mismatched document under :warn' do
      expect_mismatch_warns('tag_fields_31.yaml', [:tag_fields_before32, :tag_fields_before32, :tag_fields_before32])
    end

    it 'raises SpecViolationError on the version-mismatched document under :raise' do
      expect_mismatch_raises('tag_fields_31.yaml', [:tag_fields_before32, :tag_fields_before32, :tag_fields_before32])
    end

    it 'stays clean on the correctly-versioned document' do
      expect_clean('tag_fields_32.yaml')
    end
  end
end

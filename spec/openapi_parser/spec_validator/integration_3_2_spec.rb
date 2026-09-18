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

  describe 'XML Object nodeType (3.2 addition)' do
    it 'warns on the version-mismatched document under :warn' do
      expect_mismatch_warns('xml_node_type_31.yaml', [:xml_node_type_before32])
    end

    it 'raises SpecViolationError on the version-mismatched document under :raise' do
      expect_mismatch_raises('xml_node_type_31.yaml', [:xml_node_type_before32])
    end

    it 'stays clean on the correctly-versioned document' do
      expect_clean('xml_node_type_32.yaml')
    end
  end

  describe 'XML Object attribute/wrapped (deprecated in 3.2)' do
    it 'warns on the 3.2 document still using the deprecated fields under :warn' do
      expect_mismatch_warns('xml_deprecated_fields_32.yaml', [:xml_attribute_deprecation, :xml_wrapped_deprecation])
    end

    it 'raises SpecViolationError on the 3.2 document under :raise' do
      expect_mismatch_raises('xml_deprecated_fields_32.yaml', [:xml_attribute_deprecation, :xml_wrapped_deprecation])
    end

    it 'stays clean on the 3.1 document (fields legitimate before 3.2)' do
      expect_clean('xml_deprecated_fields_31.yaml')
    end
  end

  describe 'components.mediaTypes (3.2 addition)' do
    it 'warns on the version-mismatched document under :warn' do
      expect_mismatch_warns('media_types_31.yaml', [:media_types_before32])
    end

    it 'raises SpecViolationError on the version-mismatched document under :raise' do
      expect_mismatch_raises('media_types_31.yaml', [:media_types_before32])
    end

    it 'stays clean on the correctly-versioned document' do
      expect_clean('media_types_32.yaml')
    end
  end

  describe 'Server Object name (3.2 addition)' do
    it 'warns on the version-mismatched document under :warn' do
      expect_mismatch_warns('server_name_31.yaml', [:server_name_before32])
    end

    it 'raises SpecViolationError on the version-mismatched document under :raise' do
      expect_mismatch_raises('server_name_31.yaml', [:server_name_before32])
    end

    it 'stays clean on the correctly-versioned document' do
      expect_clean('server_name_32.yaml')
    end
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

  describe 'query operation (3.2 Path Item addition)' do
    it 'warns on the version-mismatched document under :warn' do
      expect_mismatch_warns('query_method_31.yaml', [:query_method_before32])
    end

    it 'raises SpecViolationError on the version-mismatched document under :raise' do
      expect_mismatch_raises('query_method_31.yaml', [:query_method_before32])
    end

    it 'stays clean on the correctly-versioned document' do
      expect_clean('query_method_32.yaml')
    end
  end

  describe 'additionalOperations (3.2 Path Item addition)' do
    it 'warns on the version-mismatched document under :warn' do
      expect_mismatch_warns('additional_operations_31.yaml', [:additional_operations_before32])
    end

    it 'raises SpecViolationError on the version-mismatched document under :raise' do
      expect_mismatch_raises('additional_operations_31.yaml', [:additional_operations_before32])
    end

    it 'stays clean on the correctly-versioned document' do
      expect_clean('additional_operations_32.yaml')
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

  describe 'Example Object dataValue/serializedValue (3.2 additions)' do
    it 'warns on the version-mismatched document under :warn' do
      expect_mismatch_warns('example_value_fields_31.yaml', [:example_value_fields_before32, :example_value_fields_before32])
    end

    it 'raises SpecViolationError on the version-mismatched document under :raise' do
      expect_mismatch_raises('example_value_fields_31.yaml', [:example_value_fields_before32, :example_value_fields_before32])
    end

    it 'stays clean on the correctly-versioned document' do
      expect_clean('example_value_fields_32.yaml')
    end
  end

  describe 'Security Scheme deviceAuthorization/oauth2MetadataUrl/deprecated (3.2 additions)' do
    it 'warns on the version-mismatched document under :warn' do
      expect_mismatch_warns('security_scheme_fields_31.yaml', [:security_scheme_fields_before32] * 3)
    end

    it 'raises SpecViolationError on the version-mismatched document under :raise' do
      expect_mismatch_raises('security_scheme_fields_31.yaml', [:security_scheme_fields_before32] * 3)
    end

    it 'stays clean on the correctly-versioned document' do
      expect_clean('security_scheme_fields_32.yaml')
    end
  end
end

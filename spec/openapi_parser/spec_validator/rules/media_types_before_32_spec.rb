require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::MediaTypesBefore32' do
  def base_doc(openapi_version_string)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
    }
  end

  def doc_with_media_types(openapi_version_string)
    raw = base_doc(openapi_version_string)
    raw['components'] = { 'mediaTypes' => { 'PetJson' => { 'schema' => { 'type' => 'object' } } } }
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def doc_without_media_types(openapi_version_string)
    raw = base_doc(openapi_version_string)
    raw['components'] = { 'schemas' => { 'Sample' => { 'type' => 'string' } } }
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::MediaTypesBefore32.new(root.openapi_version).check(root)
  end

  context 'with a 3.2 document using components.mediaTypes' do
    it 'reports no violation' do
      root = doc_with_media_types('3.2.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.2 document without components.mediaTypes' do
    it 'reports no violation' do
      root = doc_without_media_types('3.2.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document using components.mediaTypes' do
    it 'reports one violation pointing at the section' do
      root = doc_with_media_types('3.1.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/components/mediaTypes'
      expect(violations.first.rule_name).to eq :media_types_before32
    end
  end

  context 'with a 3.1 document without components.mediaTypes' do
    it 'reports no violation' do
      root = doc_without_media_types('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using components.mediaTypes' do
    it 'reports one violation' do
      root = doc_with_media_types('3.0.0')
      expect(run_rule_for(root).size).to eq 1
    end
  end

  context 'with a document that has no components section' do
    it 'reports no violation' do
      root = OpenAPIParser.parse(base_doc('3.1.0'), strict_reference_validation: false)
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)' do
      root = doc_with_media_types('not-a-version')
      expect(run_rule_for(root)).to eq []
    end
  end
end

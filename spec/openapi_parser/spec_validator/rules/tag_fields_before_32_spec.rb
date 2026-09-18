require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::TagFieldsBefore32' do
  def base_doc(openapi_version_string, tags)
    doc = {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
    }
    doc['tags'] = tags if tags
    doc
  end

  def doc_with_tag_fields(openapi_version_string)
    tags = [
      { 'name' => 'pets', 'summary' => 'Pets', 'kind' => 'nav' },
      { 'name' => 'pets/dogs', 'parent' => 'pets' },
    ]
    OpenAPIParser.parse(base_doc(openapi_version_string, tags), strict_reference_validation: false)
  end

  def doc_without_tag_fields(openapi_version_string)
    tags = [{ 'name' => 'pets', 'description' => 'All pets' }]
    OpenAPIParser.parse(base_doc(openapi_version_string, tags), strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::TagFieldsBefore32.new(root.openapi_version).check(root)
  end

  context 'with a 3.2 document using the new tag fields' do
    it 'reports no violation' do
      root = doc_with_tag_fields('3.2.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.2 document without the new tag fields' do
    it 'reports no violation' do
      root = doc_without_tag_fields('3.2.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document using the new tag fields' do
    it 'reports one violation per offending field pointing at the tag' do
      root = doc_with_tag_fields('3.1.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 3
      expect(violations.map(&:path)).to match_array [
        '#/tags/0/summary',
        '#/tags/0/kind',
        '#/tags/1/parent',
      ]
      expect(violations.first.rule_name).to eq :tag_fields_before32
    end
  end

  context 'with a 3.1 document without the new tag fields' do
    it 'reports no violation' do
      root = doc_without_tag_fields('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using the new tag fields' do
    it 'reports violations' do
      root = doc_with_tag_fields('3.0.0')
      expect(run_rule_for(root).size).to eq 3
    end
  end

  context 'with a document that has no tags array' do
    it 'reports no violation' do
      root = OpenAPIParser.parse(base_doc('3.1.0', nil), strict_reference_validation: false)
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)' do
      root = doc_with_tag_fields('not-a-version')
      expect(run_rule_for(root)).to eq []
    end
  end
end

require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::ServerNameBefore32' do
  def base_doc(openapi_version_string)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {
        '/pets' => {
          'get' => { 'responses' => { '200' => { 'description' => 'OK' } } },
        },
      },
    }
  end

  def doc_with_server_name(openapi_version_string)
    raw = base_doc(openapi_version_string)
    raw['servers'] = [{ 'url' => 'https://api.example.com', 'name' => 'production' }]
    raw['paths']['/pets']['servers'] = [{ 'url' => 'https://path.example.com', 'name' => 'path' }]
    raw['paths']['/pets']['get']['servers'] = [{ 'url' => 'https://alt.example.com', 'name' => 'alt' }]
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def doc_without_server_name(openapi_version_string)
    raw = base_doc(openapi_version_string)
    raw['servers'] = [{ 'url' => 'https://api.example.com' }]
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::ServerNameBefore32.new(root.openapi_version).check(root)
  end

  context 'with a 3.2 document using server name' do
    it 'reports no violation' do
      root = doc_with_server_name('3.2.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.2 document without server name' do
    it 'reports no violation' do
      root = doc_without_server_name('3.2.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document using server name at root, path item, and operation level' do
    it 'reports one violation per offending server' do
      root = doc_with_server_name('3.1.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 3
      expect(violations.map(&:path)).to match_array [
        '#/servers/0/name',
        '#/paths/~1pets/servers/0/name',
        '#/paths/~1pets/get/servers/0/name',
      ]
      expect(violations.first.rule_name).to eq :server_name_before32
    end
  end

  context 'with a 3.1 document without server name' do
    it 'reports no violation' do
      root = doc_without_server_name('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using server name' do
    it 'reports violations' do
      root = doc_with_server_name('3.0.0')
      expect(run_rule_for(root).size).to eq 3
    end
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)' do
      root = doc_with_server_name('not-a-version')
      expect(run_rule_for(root)).to eq []
    end
  end
end

require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::WebhooksIn30' do
  def base_doc(openapi_version_string)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
    }
  end

  def doc_with_webhooks(openapi_version_string)
    raw = base_doc(openapi_version_string)
    raw['webhooks'] = {
      'newPet' => { 'post' => { 'responses' => { '200' => { 'description' => 'ok' } } } },
    }
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def doc_without_webhooks(openapi_version_string)
    OpenAPIParser.parse(base_doc(openapi_version_string), strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::WebhooksIn30.new(root.openapi_version).check(root)
  end

  context 'with a 3.1 document declaring webhooks' do
    it 'reports no violation' do
      root = doc_with_webhooks('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document without webhooks' do
    it 'reports no violation' do
      root = doc_without_webhooks('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document declaring webhooks' do
    it 'reports one violation pointing at #/webhooks' do
      root = doc_with_webhooks('3.0.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/webhooks'
      expect(violations.first.rule_name).to eq :webhooks_in30
    end
  end

  context 'with a 3.0 document without webhooks' do
    it 'reports no violation' do
      root = doc_without_webhooks('3.0.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with an :unknown version document declaring webhooks' do
    it 'reports no violation (rule skipped)' do
      root = doc_with_webhooks('4.0.0')
      expect(run_rule_for(root)).to eq []
    end
  end
end

RSpec.describe 'OpenAPI#webhooks parse layer' do
  let(:root) do
    raw = {
      'openapi' => '3.1.0',
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'webhooks' => {
        'newPet' => { 'post' => { 'responses' => { '200' => { 'description' => 'ok' } } } },
      },
    }
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  it 'exposes webhooks as a Hash of PathItem' do
    expect(root.webhooks).to be_a(Hash)
    expect(root.webhooks['newPet']).to be_a(OpenAPIParser::Schemas::PathItem)
  end
end

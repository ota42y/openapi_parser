require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::SelfBefore32' do
  def base_doc(openapi_version_string)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
    }
  end

  def doc_with_self(openapi_version_string)
    raw = base_doc(openapi_version_string).merge('$self' => 'https://example.com/openapi.yaml')
    OpenAPIParser.parse(raw, strict_reference_validation: false)
  end

  def doc_without_self(openapi_version_string)
    OpenAPIParser.parse(base_doc(openapi_version_string), strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::SelfBefore32.new(root.openapi_version).check(root)
  end

  context 'with a 3.2 document using $self' do
    it 'reports no violation' do
      root = doc_with_self('3.2.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.2 document without $self' do
    it 'reports no violation' do
      root = doc_without_self('3.2.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document using $self' do
    it 'reports one violation pointing at the root field' do
      root = doc_with_self('3.1.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 1
      expect(violations.first.path).to eq '#/$self'
      expect(violations.first.rule_name).to eq :self_before32
    end
  end

  context 'with a 3.1 document without $self' do
    it 'reports no violation' do
      root = doc_without_self('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using $self' do
    it 'reports one violation' do
      root = doc_with_self('3.0.0')
      expect(run_rule_for(root).size).to eq 1
    end
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)' do
      root = doc_with_self('not-a-version')
      expect(run_rule_for(root)).to eq []
    end
  end
end

RSpec.describe 'OpenAPI#self_uri parse layer' do
  it 'exposes $self as a String' do
    raw = {
      'openapi' => '3.2.0',
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      '$self' => 'https://example.com/openapi.yaml',
    }
    root = OpenAPIParser.parse(raw, strict_reference_validation: false)
    expect(root.self_uri).to eq 'https://example.com/openapi.yaml'
  end

  it 'is nil when $self is absent' do
    raw = { 'openapi' => '3.2.0', 'info' => { 'title' => 'test', 'version' => '1.0' }, 'paths' => {} }
    root = OpenAPIParser.parse(raw, strict_reference_validation: false)
    expect(root.self_uri).to be_nil
  end
end

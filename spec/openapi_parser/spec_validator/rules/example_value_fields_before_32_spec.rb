require_relative '../../../spec_helper'

RSpec.describe 'OpenAPIParser::SpecValidator::Rules::ExampleValueFieldsBefore32' do
  def base_doc(openapi_version_string, example)
    {
      'openapi' => openapi_version_string,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {
        '/pets' => {
          'post' => {
            'requestBody' => {
              'content' => {
                'application/json' => {
                  'schema' => { 'type' => 'object' },
                  'examples' => { 'dog' => example },
                },
              },
            },
            'responses' => { '201' => { 'description' => 'Created' } },
          },
        },
      },
    }
  end

  def doc_with_value_fields(openapi_version_string)
    example = {
      'summary' => 'A dog',
      'dataValue' => { 'name' => 'Rex' },
      'serializedValue' => '{"name":"Rex"}',
    }
    OpenAPIParser.parse(base_doc(openapi_version_string, example), strict_reference_validation: false)
  end

  def doc_without_value_fields(openapi_version_string)
    example = { 'summary' => 'A dog', 'value' => { 'name' => 'Rex' } }
    OpenAPIParser.parse(base_doc(openapi_version_string, example), strict_reference_validation: false)
  end

  def run_rule_for(root)
    OpenAPIParser::SpecValidator::Rules::ExampleValueFieldsBefore32.new(root.openapi_version).check(root)
  end

  context 'with a 3.2 document using dataValue and serializedValue' do
    it 'reports no violation' do
      root = doc_with_value_fields('3.2.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.2 document using only the classic value field' do
    it 'reports no violation' do
      root = doc_without_value_fields('3.2.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.1 document using dataValue and serializedValue' do
    it 'reports one violation per offending field pointing at the example' do
      root = doc_with_value_fields('3.1.0')
      violations = run_rule_for(root)
      expect(violations.size).to eq 2
      expect(violations.map(&:path)).to match_array [
        '#/paths/~1pets/post/requestBody/content/application~1json/examples/dog/dataValue',
        '#/paths/~1pets/post/requestBody/content/application~1json/examples/dog/serializedValue',
      ]
      expect(violations.first.rule_name).to eq :example_value_fields_before32
    end
  end

  context 'with a 3.1 document using only the classic value field' do
    it 'reports no violation' do
      root = doc_without_value_fields('3.1.0')
      expect(run_rule_for(root)).to eq []
    end
  end

  context 'with a 3.0 document using dataValue and serializedValue' do
    it 'reports violations' do
      root = doc_with_value_fields('3.0.0')
      expect(run_rule_for(root).size).to eq 2
    end
  end

  context 'with a 3.1 document using the new fields on parameters, headers, and components' do
    let(:example) { { 'dataValue' => { 'name' => 'Rex' } } }
    let(:root) do
      raw = base_doc('3.1.0', { 'value' => {} })
      post = raw['paths']['/pets']['post']
      post['parameters'] = [{ 'name' => 'q', 'in' => 'query', 'schema' => { 'type' => 'string' }, 'examples' => { 'rex' => example } }]
      post['responses']['201']['headers'] = { 'X-Id' => { 'schema' => { 'type' => 'string' }, 'examples' => { 'rex' => example } } }
      raw['components'] = { 'examples' => { 'shared/rex' => example } }
      OpenAPIParser.parse(raw, strict_reference_validation: false)
    end

    it 'reports each location, escaping slashes in example names' do
      expect(run_rule_for(root).map(&:path)).to match_array [
        '#/paths/~1pets/post/parameters/0/examples/rex/dataValue',
        '#/paths/~1pets/post/responses/201/headers/X-Id/examples/rex/dataValue',
        '#/components/examples/shared~1rex/dataValue',
      ]
    end
  end

  context 'with a document whose openapi field is not a version' do
    it 'reports no violation (rule skipped)' do
      root = doc_with_value_fields('not-a-version')
      expect(run_rule_for(root)).to eq []
    end
  end
end

require_relative '../../spec_helper'

# OpenAPI 3.1.1 follows JSON Schema: 1 and 1.0 are both integers.
# OpenAPI 3.0.3 defines an integer as a JSON number without a fraction or
# exponent part, so 1.0 is not an integer there.
RSpec.describe 'integer with a zero fractional part' do
  let(:options) { ::OpenAPIParser::SchemaValidator::Options.new }
  let(:openapi_version) { '3.1.0' }
  let(:root) do
    raw = {
      'openapi' => openapi_version,
      'info' => { 'title' => 'test', 'version' => '1.0' },
      'paths' => {},
      'components' => { 'schemas' => schemas },
    }
    OpenAPIParser.parse(raw, strict_reference_validation: true)
  end
  let(:schema) { root.components.schemas['Target'] }

  def validate(value)
    OpenAPIParser::SchemaValidator.validate(value, schema, options)
  end

  context 'when a 3.1 document has type: integer' do
    it 'accepts a Float with no fractional part'
    it 'rejects a Float with a fractional part'
  end

  context 'when a 3.0 document has type: integer' do
    it 'rejects a Float with no fractional part'
  end

  context 'when a 3.1 document has integer in a type array' do
    it 'accepts a Float with no fractional part'
    it 'rejects a Float with a fractional part'
  end

  context 'when a 3.0 document has integer in a type array' do
    it 'rejects a Float with no fractional part'
  end

  context 'when a 3.1 document has other keywords on type: integer' do
    it 'applies enum'
    it 'applies maximum'
  end

  context 'when coerce_value is on' do
    it 'converts a Float with no fractional part in a 3.0 document as before'
  end

  context 'when the Float is not finite' do
    it 'rejects Infinity in a 3.1 document'
  end
end

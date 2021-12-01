require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Expandable do
  let(:root) { OpenAPIParser.parse(normal_schema, {}) }

  describe 'expand_reference' do
    subject { root }

    it do
      subject
      expect(subject.find_object('#/paths/~1reference/get/parameters/0').class).to eq OpenAPIParser::Schemas::Parameter
      expect(subject.find_object('#/paths/~1reference/get/responses/default').class).to eq OpenAPIParser::Schemas::Response
      expect(subject.find_object('#/paths/~1reference/post/responses/default').class).to eq OpenAPIParser::Schemas::Response
      path = '#/paths/~1string_params_coercer/post/requestBody/content/application~1json/schema/properties/nested_array'
      expect(subject.find_object(path).class).to eq OpenAPIParser::Schemas::Schema
    end

    context 'undefined spec references' do
      let(:invalid_reference) { '#/paths/~1ref-sample~1broken_reference/get/requestBody' }
      let(:not_configured) { {} }
      let(:raise_on_invalid_reference) { { strict_reference_validation: true } }

      it 'raises when configured to do so' do
        subject = OpenAPIParser.parse(broken_reference_schema, raise_on_invalid_reference)
        # TODO: expect a raise
        # TODO: what should it raise?
        # expect_raises(subject.find_object(invalid_reference))
      end

      it 'does not raise when not configured, returns nil reference' do
        subject = OpenAPIParser.parse(broken_reference_schema, not_configured)
        expect(subject.find_object(invalid_reference)).to be_nil
      end
    end
  end
end

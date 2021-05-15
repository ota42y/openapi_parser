require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::RequestBody do
  let(:content_type) { 'application/json' }
  let(:http_method) { :post }
  let(:request_path) { '/pet' }
  let(:request_operation) { root.request_operation(http_method, request_path) }
  let(:params) { {} }

  context 'whith discriminator with mapping' do
    let(:root) { OpenAPIParser.parse(petstore_with_mapped_polymorphism_schema, {}) }

    context 'with valid body' do
      let(:body) do
        {
          "petType" => "Cat",
          "name" => "Mr. Cat",
          "huntingSkill" => "lazy"
        }
      end

      it 'picks correct object based on mapping and succeeds' do
        request_operation.validate_request_body(content_type, body)
      end
    end

    context 'with body missing required value' do
      let(:body) do
        {
          "petType" => "tinyLion",
          "name" => "Mr. Cat"
        }

      end

      it 'picks correct object based on mapping and fails' do
        expect { request_operation.validate_request_body(content_type, body) }.to raise_error do |e|
          expect(e).to be_kind_of(OpenAPIParser::NotExistRequiredKey)
          expect(e.message).to end_with("missing required parameters: huntingSkill")
        end
      end
    end

    context 'with body containing unresolvable discriminator mapping' do
      let(:body) do
        {
          "petType" => "coolCow",
          "name" => "Ms. Cow"
        }
      end

      it "throws error" do
        expect { request_operation.validate_request_body(content_type, body) }.to raise_error do |e|
          expect(e.kind_of?(OpenAPIParser::NotExistDiscriminatorMappedSchema)).to eq true
          expect(e.message).to match("^discriminator mapped schema #/components/schemas/coolCow does not exist.*?$")
        end
      end
    end

    context 'with body missing discriminator propertyName' do
      let(:body) do
        {
          "name" => "Mr. Cat",
          "huntingSkill" => "lazy"
        }
      end

      it "throws error if discriminator propertyName is not present on object" do
        expect { request_operation.validate_request_body(content_type, body) }.to raise_error do |e|
          expect(e.kind_of?(OpenAPIParser::NotExistDiscriminatorPropertyName)).to eq true
          expect(e.message).to match("^discriminator propertyName petType does not exist in value.*?$")
        end
      end
    end
  end

  describe 'discriminator without mapping' do
    let(:root) { OpenAPIParser.parse(petstore_with_polymorphism_schema, {}) }

    context 'with valid body' do
      let(:body) do
        {
          "petType" => "Cat",
          "name" => "Mr. Cat",
          "huntingSkill" => "lazy"
        }
      end

      it 'picks correct object based on mapping and succeeds' do
        request_operation.validate_request_body(content_type, body)
      end
    end

    context 'with body missing required value' do
      let(:body) do
        {
          "petType" => "Cat",
          "name" => "Mr. Cat"
        }

      end

      it 'picks correct object based on mapping and fails' do
        expect { request_operation.validate_request_body(content_type, body) }.to raise_error do |e|
          expect(e).to be_kind_of(OpenAPIParser::NotExistRequiredKey)
          expect(e.message).to end_with("missing required parameters: huntingSkill")
        end
      end
    end

    context 'with body containing unresolvable discriminator mapping' do
      let(:body) do
        {
          "petType" => "Cow",
          "name" => "Ms. Cow"
        }
      end

      it "throws error" do
        expect { request_operation.validate_request_body(content_type, body) }.to raise_error do |e|
          expect(e.kind_of?(OpenAPIParser::NotExistDiscriminatorMappedSchema)).to eq true
          expect(e.message).to match("^discriminator mapped schema #/components/schemas/Cow does not exist.*?$")
        end
      end
    end

    context 'with body missing discriminator propertyName' do
      let(:body) do
        {
          "name" => "Mr. Cat",
          "huntingSkill" => "lazy"
        }
      end

      it "throws error if discriminator propertyName is not present on object" do
        expect { request_operation.validate_request_body(content_type, body) }.to raise_error do |e|
          expect(e.kind_of?(OpenAPIParser::NotExistDiscriminatorPropertyName)).to eq true
          expect(e.message).to match("^discriminator propertyName petType does not exist in value.*?$")
        end
      end
    end
  end
end

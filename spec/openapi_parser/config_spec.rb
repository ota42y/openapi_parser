require_relative '../spec_helper'

RSpec.describe OpenAPIParser::Config do
  describe '#strict_specification_version' do
    context 'when the option is not provided' do
      it 'defaults to :silent' do
        config = OpenAPIParser::Config.new(strict_reference_validation: false)
        expect(config.strict_specification_version).to eq :silent
      end
    end

    context 'when set to :warn' do
      it 'returns :warn' do
        config = OpenAPIParser::Config.new(
          strict_reference_validation: false,
          strict_specification_version: :warn,
        )
        expect(config.strict_specification_version).to eq :warn
      end
    end

    context 'when set to :raise' do
      it 'returns :raise' do
        config = OpenAPIParser::Config.new(
          strict_reference_validation: false,
          strict_specification_version: :raise,
        )
        expect(config.strict_specification_version).to eq :raise
      end
    end
  end
end

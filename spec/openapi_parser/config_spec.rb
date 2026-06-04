require_relative '../spec_helper'

RSpec.describe OpenAPIParser::Config do
  describe '#strict_specification_version' do
    context 'when the option is not provided' do
      it 'defaults to :silent'
    end

    context 'when set to :warn' do
      it 'returns :warn'
    end

    context 'when set to :raise' do
      it 'returns :raise'
    end
  end
end

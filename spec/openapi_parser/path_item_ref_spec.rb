require_relative '../spec_helper'

RSpec.describe 'path item $ref' do
  let(:root) { OpenAPIParser.parse_with_filepath(
    path_item_ref_schema, path_item_ref_schema_path, {})
  }
  let(:request_operation) { root.request_operation(:post, '/ref-sample') }

  it 'understands path item $ref' do
    ret = request_operation.validate_request_body('application/json', { 'test' => 'test' })
    expect(ret).to eq({ 'test' => "test" })
  end
end

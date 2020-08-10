require_relative '../spec_helper'

RSpec.describe OpenAPIParser::PathItemFinder do
  let(:root) { OpenAPIParser.parse(petstore_schema, {}) }

  describe 'parse_path_parameters' do
    subject { OpenAPIParser::PathItemFinder.new(root.paths) }

    it 'matches a single parameter with no additional characters' do
      result = subject.parse_path_parameters('{id}', '123')
      expect(result).to eq({'id' => '123'})
    end

    it 'matches a single parameter with extension' do
      result = subject.parse_path_parameters('{id}.json', '123.json')
      expect(result).to eq({'id' => '123'})
    end

    it 'matches a single parameter with additional characters' do
      result = subject.parse_path_parameters('stuff_{id}_hoge', 'stuff_123_hoge')
      expect(result).to eq({'id' => '123'})
    end

    it 'matches multiple parameters with additional characters' do
      result = subject.parse_path_parameters('{stuff_with_underscores-and-hyphens}_{id}_hoge', '4_123_hoge')
      expect(result).to eq({'stuff_with_underscores-and-hyphens' => '4', 'id' => '123'})
    end

    it 'fails to match' do
      result = subject.parse_path_parameters('stuff_{id}_', '123')
      expect(result).to be_nil

      result = subject.parse_path_parameters('{p1}-{p2}.json', 'foo.json')
      expect(result).to be_nil

      result = subject.parse_path_parameters('{p1}.json', 'foo.txt')
      expect(result).to be_nil
    end

    it 'fails to match no input' do
      result = subject.parse_path_parameters('', '')
      expect(result).to be_nil
    end

    it 'matches when the last character of the variable is the same as the next character' do
      result = subject.parse_path_parameters('{p1}schedule', 'adminsschedule')
      expect(result).to eq({'p1' => 'admins'})

      result = subject.parse_path_parameters('{p1}schedule', 'usersschedule')
      expect(result).to eq({'p1' => 'users'})
    end
  end

  describe 'find' do
    subject { OpenAPIParser::PathItemFinder.new(root.paths) }

    it do
      expect(subject.class).to eq OpenAPIParser::PathItemFinder

      result = subject.operation_object(:get, '/pets')
      expect(result.class).to eq OpenAPIParser::PathItemFinder::Result
      expect(result.original_path).to eq('/pets')
      expect(result.operation_object.object_reference).to eq root.find_object('#/paths/~1pets/get').object_reference
      expect(result.path_params.empty?).to eq true

      result = subject.operation_object(:get, '/pets/1')
      expect(result.original_path).to eq('/pets/{id}')
      expect(result.operation_object.object_reference).to eq root.find_object('#/paths/~1pets~1{id}/get').object_reference
      expect(result.path_params['id']).to eq '1'

      result = subject.operation_object(:post, '/pets/lessie/adopt/123')
      expect(result.original_path).to eq('/pets/{nickname}/adopt/{param_2}')
      expect(result.operation_object.object_reference)
        .to eq root.find_object('#/paths/~1pets~1{nickname}~1adopt~1{param_2}/post').object_reference
      expect(result.path_params['nickname']).to eq 'lessie'
      expect(result.path_params['param_2']).to eq '123'
    end

    it 'matches path items that end in a file extension' do
      result = subject.operation_object(:get, '/animals/123/456.json')
      expect(result.original_path).to eq('/animals/{groupId}/{id}.json')
      expect(result.operation_object.object_reference).to eq root.find_object('#/paths/~1animals~1{groupId}~1{id}.json/get').object_reference
      expect(result.path_params['groupId']).to eq '123'
      expect(result.path_params['id']).to eq '456'
    end

    it 'ignores invalid HTTP methods' do
      expect(subject.operation_object(:exit, '/pets')).to eq(nil)
      expect(subject.operation_object(:blah, '/pets')).to eq(nil)
    end
  end
end

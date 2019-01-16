require_relative './value'
require_relative './object'
require_relative './list'
require_relative './hash'
require_relative './hash_body'

class OpenAPIParser::Parser::Core
  include OpenAPIParser::Parser::Value
  include OpenAPIParser::Parser::Object
  include OpenAPIParser::Parser::List
  include OpenAPIParser::Parser::Hash
  include OpenAPIParser::Parser::HashBody

  def initialize(target_klass)
    @target_klass = target_klass
  end

  # @return [Array<OpenAPIParser::SchemaLoader::Base>]
  def all_loader
    @all_loader ||= _openapi_attr_values.values +
                    _openapi_attr_objects.values +
                    _openapi_attr_list_objects.values +
                    _openapi_attr_hash_objects.values +
                    _openapi_attr_hash_body_objects.values
  end

  private

    attr_reader :target_klass
end

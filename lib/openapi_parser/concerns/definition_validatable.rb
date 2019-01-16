module OpenAPIParser::DefinitionValidatable
  def validate_definitions(parents)
    ret = []
    self.class._parser_core.all_loader.each do |loader|
      errors = loader.definition_validate(parents, self)
      ret.concat errors.compact
    end

    parents.push(self)
    _openapi_all_child_objects.values.each { |child| ret.concat child.validate_definitions(parents) }
    parents.pop

    ret
  end
end

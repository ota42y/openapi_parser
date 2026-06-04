module OpenAPIParser
  class SpecValidator
    SpecViolation = Struct.new(:message, :path, :rule_name, keyword_init: true) do
      def to_s
        "[#{rule_name}] #{path}: #{message}"
      end
    end
  end

  SpecViolation = SpecValidator::SpecViolation
end

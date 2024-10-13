lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'openapi_parser/version'

Gem::Specification.new do |spec|
  spec.name          = 'openapi_parser'
  spec.version       = OpenAPIParser::VERSION
  spec.authors       = ['ota42y']
  spec.email         = ['ota42y@gmail.com']

  spec.summary       = 'OpenAPI3 parser'
  spec.description   = 'parser for OpenAPI 3.0 or later'
  spec.homepage      = 'https://github.com/ota42y/openapi_parser'
  spec.license       = 'MIT'
  spec.required_ruby_version = ">= 2.7.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '>= 1.16'
  spec.add_development_dependency 'fincop'

  if Gem::Version.create(RUBY_VERSION) < Gem::Version.create("3.2.0")
    spec.add_development_dependency 'pry', '~> 0.12.0'
    spec.add_development_dependency 'pry-byebug'
  end
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-parameterized'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency "steep"
  # for steep + ruby-head
  spec.add_development_dependency 'base64', '~> 0.2.0'
  # https://github.com/soutaro/steep/issues/466
  spec.add_development_dependency "activesupport", '~> 6.0'
end

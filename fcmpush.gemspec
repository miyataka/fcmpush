lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fcmpush/version'

Gem::Specification.new do |spec|
  spec.name          = 'fcmpush'
  spec.version       = Fcmpush::VERSION
  spec.authors       = ['miyataka']
  spec.email         = ['voyager.3taka28@gmail.com']

  spec.summary       = 'Firebase Cloud Messaging API wrapper for ruby, supports HTTP v1. And including access_token Auto Refresh feature!'
  spec.homepage      = 'https://github.com/miyataka/fcmpush'
  spec.license       = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/miyataka/fcmpush'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").select { |f| f.match(%r{^(lib/|fcmpush.gemspec)}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'googleauth', '>= 0.9.0'
  spec.add_dependency 'net-http-persistent', '>= 3.1.0'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end

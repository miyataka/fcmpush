source 'https://rubygems.org'

# Specify your gem's dependencies in fcmpush.gemspec
gemspec

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.4')
  gem 'bigdecimal'
  gem 'drb'
end

gem 'webmock', '~> 3.18'

# multi_json releases supporting Ruby < 3.2 pass JSON.parse options positionally.
# Keep the legacy Ruby test dependency stack on the compatible JSON API.
gem 'json', '< 3' if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.2')

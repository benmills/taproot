# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Ben Mills"]
  gem.email         = ["ben@benmills.org"]
  gem.description   = %q{Braintree test server}
  gem.summary       = %q{Taproot makes it easy to develop Braintree client SDKs without a server}
  gem.homepage      = "https://github.com/benmills/taproot"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = ["taproot"]
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "taproot"
  gem.require_paths = ["lib"]
  gem.version       = "0.1.0"

  gem.add_dependency "sinatra", "~> 1.4.5"
  gem.add_dependency "braintree", "~> 2.30.2"
  gem.add_dependency "pry", "~> 0.9.12.6"
  gem.add_dependency "activesupport", "~> 4.1.1"
end

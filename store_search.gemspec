# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'store_search/version'

Gem::Specification.new do |spec|
  spec.name          = "store_search"
  spec.version       = StoreSearch::VERSION
  spec.authors       = ["Leszek Zalewski"]
  spec.email         = ["leszek.zalewski@applift.com"]
  spec.summary       = %q{Store Search.}
  spec.description   = %q{Gem for accessing App/Play Store search in an unified way.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rack"
  spec.add_dependency "addressable"
  spec.add_dependency "htmlentities"
  spec.add_dependency "market_bot", ">= 1.3"
  spec.add_dependency "sanitize"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.14"
  spec.add_development_dependency "rspec-its"
  spec.add_development_dependency "webmock"
end

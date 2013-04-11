# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'datagram/version'

Gem::Specification.new do |gem|
  gem.name          = "datagram"
  gem.version       = Datagram::VERSION
  gem.authors       = ["Brad Gessler"]
  gem.email         = ["brad@polleverywhere.com"]
  gem.description   = %q{Gist for MySQL}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "sinatra"
  gem.add_dependency "haml"
  gem.add_dependency "sequel"
end

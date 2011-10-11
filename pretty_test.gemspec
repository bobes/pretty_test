# -*- encoding: utf-8 -*-
require File.expand_path("../lib/pretty_test/version", __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Vladimir Bobes Tuzinsky"]
  gem.email         = ["vladimir@tuzinsky.com"]
  gem.summary       = %q{Minitest patch for pretty output}
  gem.description   = %q{Minitest patch for pretty (and useful) output.}
  gem.homepage      = "https://github.com/bobes/pretty_test"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "pretty_test"
  gem.require_paths = ["lib"]
  gem.version       = PrettyTest::VERSION

  gem.add_dependency "minitest", ">= 2.6"
  gem.add_dependency "minitap", ">= 0.3"
end

$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rails_versioned_routing"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails_versioned_routing"
  s.version     = RailsVersionedRouting::VERSION
  s.authors     = ["Trek Glowacki"]
  s.email       = ["trek.glowacki@gmail.com"]
  s.homepage    = "https://github.com/trek/rails_versioned_routing"
  s.summary     = "..."
  s.description = "..."

  s.files = Dir["{lib}/**/*", "LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.0.13"

  s.add_development_dependency "sqlite3"
end

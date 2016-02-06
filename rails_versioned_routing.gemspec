$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rails_versioned_routing"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails_versioned_routing"
  s.version     = RailsVersionedRouting::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of RailsVersionedRouting."
  s.description = "TODO: Description of RailsVersionedRouting."

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.0.13"

  s.add_development_dependency "sqlite3"
end

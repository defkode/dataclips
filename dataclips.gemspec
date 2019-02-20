$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "dataclips/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "dataclips"
  s.version     = Dataclips::VERSION
  s.authors     = ["Tomasz Mazur"]
  s.email       = ["defkode@gmail.com"]
  s.homepage    = "http://www.trix.pl"
  s.summary     = "Dataclips - shareable reports."
  s.description = "Heroku inspired dataclips for your application."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]
  s.add_dependency "rails", ">= 5.1.6"
  s.add_dependency "pg_clip", "0.1.4"
end

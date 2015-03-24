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
  s.add_dependency "rails",                           "~> 4.2"
  s.add_dependency "pg",                              "~> 0.18"
  s.add_dependency "jquery-rails",                    "~> 4.0"
  s.add_dependency "will_paginate",                   "~> 3.0"
  s.add_dependency "hashids",                         "~> 1.0"
  s.add_dependency "twitter-bootstrap-rails",         "~> 3.2"
  s.add_dependency "font-awesome-rails",              "~> 4.3"
  s.add_dependency "momentjs-rails",                  "~> 2.9"
  s.add_dependency "bootstrap3-datetimepicker-rails", "~> 4.7"
end

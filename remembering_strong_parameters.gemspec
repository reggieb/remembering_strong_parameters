$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "remembering_strong_parameters/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "remembering_strong_parameters"
  s.version     = RememberingStrongParameters::VERSION
  s.authors     = ['Rob Nichols', "David Heinemeier Hansson (original strong_parameters)"]
  s.email       = ['rob@undervale.co.uk']
  s.summary     = "Permitted and required parameters for Action Pack"
  s.homepage    = "https://github.com/reggieb/remembering_strong_parameters"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "actionpack", "~> 3.0"
  s.add_dependency "activemodel", "~> 3.0"

  s.add_development_dependency "rake"
  s.add_development_dependency "mocha", "~> 0.12.0"
end

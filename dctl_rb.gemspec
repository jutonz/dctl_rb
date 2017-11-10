
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dctl/version"

Gem::Specification.new do |spec|
  spec.name          = "dctl_rb"
  spec.version       = Dctl::VERSION
  spec.authors       = ["Justin Toniazzo"]
  spec.email         = ["jutonz42@gmail.com"]

  spec.summary       = "Simple dockerized app config"
  spec.homepage      = "https://github.com/jutonz/dctl_rb"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = ["dctl"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "thor", ">= 0.17.0"
  spec.add_dependency "config", ">= 1", "< 2"
  spec.add_dependency "rainbow", ">= 2.2", "< 3"
end

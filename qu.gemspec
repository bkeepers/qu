# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qu/version"

plugin_files = Dir['qu-*.gemspec'].map { |gemspec|
  eval(File.read(gemspec)).files
}.flatten.uniq

Gem::Specification.new do |s|
  s.name        = "qu"
  s.version     = Qu::VERSION
  s.authors     = ["Brandon Keepers"]
  s.email       = ["brandon@opensoul.org"]
  s.homepage    = "http://github.com/bkeepers/qu"
  s.summary     = %q{}
  s.description = %q{}

  s.files         = `git ls-files`.split("\n") - plugin_files
  s.test_files    = `git ls-files -- spec`.split("\n")
  s.executables   = `git ls-files -- bin`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'multi_json'
end

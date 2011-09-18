# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qu/version"

Gem::Specification.new do |s|
  s.name        = "qu"
  s.version     = Qu::VERSION
  s.authors     = ["Brandon Keepers"]
  s.email       = ["brandon@opensoul.org"]
  s.homepage    = ""
  s.summary     = %q{}
  s.description = %q{}

  s.files         = `git ls-files | grep -v 'redis\|mongo'`.split("\n")
  s.test_files    = `git ls-files -- spec | grep -v 'redis\|mongo'`.split("\n")
  s.executables   = `git ls-files -- bin`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'multi_json'
end

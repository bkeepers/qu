# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qu/version"

Gem::Specification.new do |s|
  s.name        = "qu-sequel"
  s.version     = Qu::VERSION
  s.authors     = ["Brandon Keepers"]
  s.email       = ["brandon@opensoul.org"]
  s.homepage    = "http://github.com/bkeepers/qu"
  s.summary     = "Sequel backend for qu"
  s.description = "Sequel backend for qu"

  s.files         = `git ls-files -- lib | grep sequel`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency 'sequel'
  s.add_dependency 'qu', Qu::VERSION

  s.add_development_dependency 'pg'
end

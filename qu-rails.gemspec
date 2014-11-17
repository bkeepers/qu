# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qu/version"

Gem::Specification.new do |s|
  s.name        = "qu-rails"
  s.version     = Qu::VERSION
  s.authors     = ["Brandon Keepers"]
  s.email       = ["brandon@opensoul.org"]
  s.homepage    = "http://github.com/bkeepers/qu"
  s.summary     = "Rails integration for qu"
  s.description = "Rails integration for qu"

  s.files         = `git ls-files -- lib | grep rails`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency 'rails', '>=3.0'
  s.add_dependency 'qu', Qu::VERSION
end

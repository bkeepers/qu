# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qu/version"

Gem::Specification.new do |s|
  s.name        = "qu-redis"
  s.version     = Qu::VERSION
  s.authors     = ["Brandon Keepers"]
  s.email       = ["brandon@opensoul.org"]
  s.homepage    = "http://github.com/bkeepers/qu"
  s.summary     = "Redis backend for qu"
  s.description = "Redis backend for qu"

  s.files         = `git ls-files -- lib | grep redis`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency 'redis-namespace'
  s.add_dependency 'qu', Qu::VERSION
end

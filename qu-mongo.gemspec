# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qu/version"

Gem::Specification.new do |s|
  s.name        = "qu-mongo"
  s.version     = Qu::VERSION
  s.authors     = ["Brandon Keepers"]
  s.email       = ["brandon@opensoul.org"]
  s.homepage    = "http://github.com/bkeepers/qu"
  s.summary     = "Mongo queue for qu"
  s.description = "Mongo queue for qu"

  s.files         = `git ls-files -- lib | grep mongo`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency 'mongo', '~> 1.9.0'
  s.add_dependency 'qu', Qu::VERSION

  s.add_development_dependency 'bson_ext', '~> 1.9.0'
end

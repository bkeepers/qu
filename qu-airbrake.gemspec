# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qu/version"

Gem::Specification.new do |s|
  s.name        = "qu-airbrake"
  s.version     = Qu::VERSION
  s.authors     = ["Brandon Keepers", "Scott Ellard"]
  s.email       = ["brandon@opensoul.org"]
  s.homepage    = "http://github.com/bkeepers/qu"
  s.summary     = "Airbrake failure backend for qu"
  s.description = "Airbrake failure backend for qu"

  s.files         = `git ls-files -- lib | grep airbrake`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency 'airbrake'
  s.add_dependency 'i18n'
  s.add_dependency 'qu', Qu::VERSION
end
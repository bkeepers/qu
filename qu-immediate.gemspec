# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qu/version"

Gem::Specification.new do |s|
  s.name        = "qu-immediate"
  s.version     = Qu::VERSION
  s.authors     = ["Brandon Keepers"]
  s.email       = ["brandon@opensoul.org"]
  s.homepage    = "http://github.com/bkeepers/qu"
  s.summary     = 'Immediate "backend" for qu'
  s.description = 'Immediate "backend" for qu'

  s.files         = `git ls-files -- lib | grep immediate`.split("\n")
  s.require_paths = ["lib"]
end

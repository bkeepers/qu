# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qu/version"

Gem::Specification.new do |s|
  s.name        = "qu-nsq-http"
  s.version     = Qu::VERSION
  s.authors     = ["Grant Rodgers"]
  s.email       = ["grantr@gmail.com"]
  s.homepage    = "http://github.com/bkeepers/qu"
  s.summary     = "NSQ HTTP backend for qu"
  s.description = "NSQ HTTP backend for qu"

  s.files         = `git ls-files -- lib | grep nsq-http`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency 'qu', Qu::VERSION

  s.add_development_dependency 'nsq-cluster'
end

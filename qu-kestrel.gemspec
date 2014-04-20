# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qu/version"

Gem::Specification.new do |s|
  s.name        = "qu-kestrel"
  s.version     = Qu::VERSION
  s.authors     = ["John Nunemaker"]
  s.email       = ["nunemaker@gmail.com"]
  s.homepage    = "http://github.com/bkeepers/qu"
  s.summary     = "Kestrel backend for qu"
  s.description = "Kestrel backend for qu"

  s.files         = `git ls-files -- lib | grep sqs`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency 'thrift_client', '~> 0.8.0'
  s.add_dependency 'qu', Qu::VERSION
end

# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qu/version"

Gem::Specification.new do |s|
  s.name        = "qu-sqs"
  s.version     = Qu::VERSION
  s.authors     = ["John Nunemaker"]
  s.email       = ["nunemaker@gmail.com"]
  s.homepage    = "http://github.com/bkeepers/qu"
  s.summary     = "SQS backend for qu"
  s.description = "SQS backend for qu"

  s.files         = `git ls-files -- lib | grep sqs`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency 'aws-sdk', '~> 1.0'
  s.add_dependency 'qu', Qu::VERSION

  s.add_development_dependency 'fake_sqs', '~> 0.0.10'
end

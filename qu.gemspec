# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qu/version"

plugins = Dir['qu-*.gemspec'].map {|gemspec| gemspec.scan(/qu-(.*)\.gemspec/).flatten.first }.join('\|')

Gem::Specification.new do |s|
  s.name        = "qu"
  s.version     = Qu::VERSION
  s.authors     = ["Brandon Keepers"]
  s.email       = ["brandon@opensoul.org"]
  s.homepage    = "http://github.com/bkeepers/qu"
  s.summary     = %q{}
  s.description = %q{}

  s.files         = `git ls-files | grep -v '#{plugins}'`.split("\n")
  s.test_files    = `git ls-files -- spec | grep -v '#{plugins}'`.split("\n")
  s.executables   = `git ls-files -- bin`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'multi_json', '~> 1.0'
end

# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qu/version"

desc 'Build gem into the pkg directory'
task :build do
  FileUtils.rm_rf('pkg')
  Dir['*.gemspec'].each do |gemspec|
    system "gem build #{gemspec}"
  end
  FileUtils.mkdir_p('pkg')
  FileUtils.mv(Dir['*.gem'], 'pkg')
end

desc 'Tags version, pushes to remote, and pushes gem'
task :release => :build do
  sh 'git', 'tag', '-m', changelog, "v#{Qu::VERSION}"
  sh "git push origin master"
  sh "git push origin v#{Qu::VERSION}"
  sh "ls pkg/*.gem | xargs -n 1 gem push"
end

require 'rspec/core/rake_task'

desc "Run all specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w[--color]
  t.verbose = false
end

namespace :spec do
  Backends = %w(mongo redis)

  Backends.each do |backend|
    desc "Run specs for #{backend} backend"
    RSpec::Core::RakeTask.new(backend) do |t|
      t.rspec_opts = %w[--color]
      t.verbose = false
      t.pattern = "spec/qu/backend/#{backend}_spec.rb"
    end
  end

  task :backends => Backends
end

def changelog
  File.read('ChangeLog').split("\n\n\n", 2).first
end

task :default => :spec
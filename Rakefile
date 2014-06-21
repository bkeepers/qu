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
  Backends = %w(kestrel mongo redis sqs)

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

desc "Start fake services, run tests, cleanup"
task :unattended_spec do |t|
  require 'tmpdir'
  require 'socket'

  system "script/kestrel"
  kestrel_pid = File.read("tmp/kestrel.pid").chomp.to_i

  dir = Dir.mktmpdir
  data_file = File.join(dir, "data.fdb")

  sqs_pid = Process.spawn 'fake_sqs', '-p', '5111', err: '/dev/null', out: '/dev/null'

  at_exit {
    Process.kill('TERM', kestrel_pid)
    Process.kill('TERM', sqs_pid)
    FileUtils.rmtree(dir)
  }

  40.downto(0) do |count|
    begin
      s = TCPSocket.new 'localhost', 5111
      s.close
      break
    rescue Errno::ECONNREFUSED
      raise if count == 0
      sleep 0.1
    end
  end

  Rake::Task["spec"].invoke
end

task :default => :unattended_spec

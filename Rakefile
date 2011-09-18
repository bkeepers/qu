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

task :default => :spec
namespace :qu do
  desc "Start a worker"
  task :work  => :environment do
    queues = (ENV['QUEUES'] || ENV['QUEUE'] || 'default').to_s.split(',')
    Qu::Worker.new(*queues).start
  end
end

# Convenience tasks compatibility
task 'jobs:work'   => 'qu:work'
task 'resque:work' => 'qu:work'

# No-op task in case it doesn't already exist
task :environment
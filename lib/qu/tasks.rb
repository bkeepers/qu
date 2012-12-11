namespace :qu do
  desc "Start a worker"
  task :work  => :environment do
    queues = (ENV['QUEUES'] || ENV['QUEUE'] || 'default').to_s.split(',')
    worker = Qu::Worker.new(*queues)
    begin
      worker.start
    rescue Qu::Worker::Abort
      Qu.logger.debug "Worker #{worker.id} aborted"
    end
  end
end

# Convenience tasks compatibility
task 'jobs:work'   => 'qu:work'
task 'resque:work' => 'qu:work'

# No-op task in case it doesn't already exist
task :environment
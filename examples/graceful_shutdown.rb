# Example of how Qu works with graceful shutdown turned on.
require_relative './example_setup'

Qu.configure do |config|
  config.graceful_shutdown = true
end

class SleepJob < Qu::Job
  def initialize(sleep_for = 3)
    @sleep_for = sleep_for
  end

  def perform
    logger.debug "Performing job, sleeping for #{@sleep_for}"
    sleep @sleep_for
    logger.debug 'Job complete'
  end
end

SleepJob.create

# tell qu worker to terminate after a wee bit
Thread.new { sleep 0.1; Process.kill 'SIGTERM', $$ }

worker = Qu::Worker.new
begin
  worker.start
rescue Qu::Worker::Stop
  puts 'Received stop. Worker done.'
end

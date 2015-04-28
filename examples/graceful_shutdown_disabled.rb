# Example of how Qu works with graceful shutdown turned off.
require_relative './example_setup'

Qu.configure do |config|
  config.graceful_shutdown = false
end

class SleepJob < Qu::Job
  queue :redis

  def initialize(sleep_for = 3)
    @sleep_for = sleep_for
  end

  def perform
    logger.debug "Performing job, sleeping for #{@sleep_for}"
    sleep @sleep_for
    logger.debug 'Job complete'
  end
end

# job created
SleepJob.create 3
Qu.logger.info "# of jobs: #{Qu.queues[:redis].size}"

# die before job is performed
work_and_die 0.1, :redis

# job is aborted and pushed back on queue
Qu.logger.info "# of jobs: #{Qu.queues[:redis].size}"

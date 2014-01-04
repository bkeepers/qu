# Example of how Qu works with graceful shutdown turned off.
require_relative './example_setup'

Qu.configure do |config|
  config.graceful_shutdown = false
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

SleepJob.create 3

work_and_die 0.1

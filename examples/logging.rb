# Example of how Qu works with graceful shutdown turned on.
require_relative './example_setup'
require 'qu/instrumentation/log_subscriber'

class SimpleJob < Qu::Job
end

SimpleJob.create
SimpleJob.create

work_and_die

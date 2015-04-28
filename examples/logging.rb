require_relative './example_setup'
require 'qu/instrumentation/log_subscriber'

class SimpleJob < Qu::Job
  queue :redis
end

SimpleJob.create
SimpleJob.create

work_and_die

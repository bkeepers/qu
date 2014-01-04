# Example of how Qu works with graceful shutdown turned on.
require_relative './example_setup'

Qu.configure do |config|
  config.graceful_shutdown = true
end

class CallThePresident < Qu::Job
  queue :low

  def perform
    logger.info 'calling the president'
  end
end

class CallTheNunes < Qu::Job
  queue :high

  def perform
    logger.info 'calling the nunes'
  end
end

CallThePresident.create('blah blah blah...')
CallTheNunes.create('blah blah blah...')

work_and_die

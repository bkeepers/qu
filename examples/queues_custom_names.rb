# Example of how Qu works with graceful shutdown turned on.
require_relative './example_setup'

class CallThePresidentJob < Qu::Job
  queue :low

  def initialize(message)
    @message = message
  end

  def perform
    logger.info "calling the president: #{@message}"
  end
end

class CallTheNunesJob < Qu::Job
  queue :high

  def initialize(message)
    @message = message
  end

  def perform
    logger.info "calling the nunes: #{@message}"
  end
end

CallThePresidentJob.create('blah blah blah...')
CallTheNunesJob.create('blah blah blah...')

work_and_die 1, :high, :low

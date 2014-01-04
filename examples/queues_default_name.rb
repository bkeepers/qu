# Example of how Qu works with graceful shutdown turned on.
require_relative './example_setup'

class CallTheNunes < Qu::Job
  def perform
    logger.info 'calling the nunes'
  end
end

payload = CallTheNunes.create

Qu.logger.info "Queue used: #{payload.queue}"

work_and_die

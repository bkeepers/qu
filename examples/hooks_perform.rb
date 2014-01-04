# Example of how Qu works with graceful shutdown turned on.
require_relative './example_setup'

Qu.configure do |config|
  config.graceful_shutdown = true
end

class Cook < Qu::Job
  around_perform :instrument

  before_perform :purchase
  after_perform :eat

  def perform
    sleep rand
    logger.info "cooking"
  end

  private

  def instrument
    start = Time.now
    yield
    duration = ((Time.now - start) * 1_000).round
    logger.info "job time: #{duration}ms"
  end

  def purchase
    logger.info "purchasing"
  end

  def eat
    logger.info "eating"
  end
end

Cook.create

work_and_die

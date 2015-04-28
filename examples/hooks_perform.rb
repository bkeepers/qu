require_relative './example_setup'

class CookJob < Qu::Job
  queue :redis

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

CookJob.create

work_and_die

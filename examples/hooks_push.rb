# Example of how Qu works with graceful shutdown turned on.
require_relative './example_setup'

Qu.configure do |config|
  config.graceful_shutdown = true
end

class MaybeJob < Qu::Job
  before_push :determine_for_real
  after_push :log_push

  def initialize(actually_push = true)
    @actually_push = actually_push
  end

  def perform
    logger.info "performing job"
  end

  private

  def determine_for_real
    halt unless @actually_push
  end

  def log_push
    logger.info "pushed job"
  end
end

MaybeJob.create(false)
MaybeJob.create(false)
MaybeJob.create(true)
MaybeJob.create(false)
MaybeJob.create(false)

Qu.logger.info "Qu size should be 1, actual: #{Qu.size}"

work_and_die

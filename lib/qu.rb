require 'qu/version'
require 'qu/logger'
require 'qu/failure'
require 'qu/payload'
require 'qu/backend/base'

require 'forwardable'
require 'logger'

module Qu
  autoload :Worker, 'qu/worker'

  extend SingleForwardable
  extend self

  attr_accessor :backend, :failure, :logger, :max_retries_on_connection_failure, :retry_frequency_on_connection_failure

  def_delegators :backend, :length, :queues, :reserve, :clear, :connection=

  def backend
    @backend || raise("Qu backend not configured. Install one of the backend gems like qu-redis.")
  end

  def configure(&block)
    block.call(self)
  end

  def enqueue(klass, *args)
    backend.enqueue Payload.new(:klass => klass, :args => args)
  end
end

Qu.configure do |c|
  c.logger = Logger.new(STDOUT)
  c.logger.level = Logger::INFO
  c.max_retries_on_connection_failure = 5
  c.retry_frequency_on_connection_failure = 1
end

if defined?(Rails)
  if defined?(Rails::Railtie)
    require 'qu/railtie'
  else
    Qu.logger = Rails.logger
  end
end


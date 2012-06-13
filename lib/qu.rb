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

  attr_accessor :backend, :failure, :logger

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
end

if defined?(Rails)
  warn "#{Kernel.caller[1]}: [DEPRECATION] v1.0 will require you use the 'qu-rails' gem for rails hooks to be autoloaded"

  if defined?(Rails::Railtie)
    require 'qu/railtie'
  else
    Qu.logger = Rails.logger
  end
end


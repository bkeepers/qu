require 'qu/version'
require 'qu/logger'
require 'qu/hooks'
require 'qu/failure'
require 'qu/payload'
require 'qu/job'
require 'qu/backend/base'
require 'qu/worker'

require 'forwardable'
require 'logger'

module Qu
  extend SingleForwardable
  extend self

  attr_accessor :backend, :failure, :logger, :graceful_shutdown

  def_delegators :backend, :size, :clear

  def backend
    @backend || raise("Qu backend not configured. Install one of the backend gems like qu-redis.")
  end

  def configure(&block)
    block.call(self)
  end
end

Qu.configure do |c|
  c.logger = Logger.new(STDOUT)
  c.logger.level = Logger::INFO
end

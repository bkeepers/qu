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
  InstrumentationNamespace = :qu

  extend SingleForwardable
  extend self

  attr_accessor :backend, :failure, :logger, :graceful_shutdown, :instrumenter

  def_delegators :backend, :push, :pop, :size, :clear
  def_delegators :instrumenter, :instrument

  def backend
    @backend || raise("Qu backend not configured. Install one of the backend gems like qu-redis.")
  end

  def configure(&block)
    block.call(self)
  end

  # Internal: Convert an object to json.
  def dump_json(object)
    JSON.dump(object) if object
  end

  # Internal: Convert json to an object.
  def load_json(object)
    JSON.load(object) if object
  end
end

require 'qu/instrumenters/noop'

Qu.configure do |c|
  c.logger = Logger.new(STDOUT)
  c.logger.level = Logger::INFO
  c.instrumenter = Qu::Instrumenters::Noop
end

require "qu/failure/logger"

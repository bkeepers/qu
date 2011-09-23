require 'qu/version'
require 'qu/failure'
require 'qu/job'
require 'qu/backend/base'

require 'forwardable'

module Qu
  autoload :Worker, 'qu/worker'

  extend SingleForwardable
  extend self

  attr_accessor :backend, :failure

  def_delegators :backend, :enqueue, :length, :queues, :reserve, :clear, :connection=

  def backend
    @backend || raise("Qu backend not configured. Install one of the backend gems like qu-redis.")
  end

  def configure(&block)
    block.call(self)
  end
end

require 'qu/railtie' if defined?(Rails)

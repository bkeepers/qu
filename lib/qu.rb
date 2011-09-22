require 'qu/version'
require 'qu/failure'
require 'qu/job'
require 'qu/backend/base'

require 'forwardable'

module Qu
  autoload :Worker, 'qu/worker'

  extend SingleForwardable
  extend self

  def_delegators :backend, :enqueue, :length, :queues, :reserve, :clear

  attr_accessor :failure

  def backend=(backend)
    @backend = backend
  end

  def backend
    @backend ||= Backend::Redis.new
  end
end

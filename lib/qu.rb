require 'qu/version'
require 'qu/logger'
require 'qu/hooks'
require 'qu/payload'
require 'qu/job'
require 'qu/queues/base'
require 'qu/queues/instrumented'
require 'qu/instrumenters/noop'
require 'qu/runner/direct'
require 'qu/worker'
require 'qu/util/thread_safe_hash'

require 'forwardable'
require 'logger'

module Qu
  InstrumentationNamespace = :qu

  extend SingleForwardable
  extend self

  @interval = 5

  attr_accessor :logger, :graceful_shutdown, :instrumenter, :interval, :runner

  def queues
    @queues ||= Util::ThreadSafeHash.new
  end

  def register(name, instance)
    name = name.to_sym
    instance.name = name
    queues[name] = Queues::Instrumented.wrap(instance)
  end

  def unregister_queues
    queues.clear
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

  def instrument(name, payload = {}, &block)
    Qu.instrumenter.instrument("#{name}.#{InstrumentationNamespace}", payload, &block)
  end

  def subscribe(string_or_regex, &block)
    pattern = if string_or_regex.is_a?(Regexp)
      Regexp.new("^#{string_or_regex.source}\\.#{InstrumentationNamespace}$")
    else
      "#{string_or_regex}.#{InstrumentationNamespace}"
    end

    Qu.instrumenter.subscribe(pattern, &block)
  end

  def unsubscribe(subscriber)
    Qu.instrumenter.unsubscribe(subscriber)
  end
end

Qu.configure do |config|
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::INFO
  config.instrumenter = Qu::Instrumenters::Noop
  config.runner = Qu::Runner::Direct.new
end

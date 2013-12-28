require 'ostruct'
require 'forwardable'

module Qu
  class Payload < OpenStruct
    extend Forwardable
    include Logger

    undef_method(:id) if method_defined?(:id)

    def initialize(options = {})
      super
      self.args ||= []
    end

    def klass
      @klass ||= constantize(super)
    end

    def job
      @job ||= klass.load(self)
    end

    def queue
      @queue ||= (klass.instance_variable_get(:@queue) || 'default').to_s
    end

    def perform
      instrument("perform.#{InstrumentationNamespace}") do |payload|
        payload[:payload] = self
        job.run_hook(:perform) { job.perform }
      end

      instrument("complete.#{InstrumentationNamespace}") do |payload|
        payload[:payload] = self
        job.run_hook(:complete) { Qu.backend.complete(self) }
      end
    rescue Qu::Worker::Abort
      instrument("abort.#{InstrumentationNamespace}") do |payload|
        payload[:payload] = self
        job.run_hook(:abort) { Qu.backend.abort(self) }
      end
      raise
    rescue => exception
      instrument("failure.#{InstrumentationNamespace}") do |payload|
        payload[:payload] = self
        payload[:exception] = exception
        job.run_hook(:failure, exception) { Qu.failure.create(self, exception) }
      end
    end

    def to_s
      "#{id}:#{klass}:#{args.inspect}"
    end

    def attributes
      {
        :id => id,
        :klass => klass.to_s,
        :args => args,
      }
    end

    # Internal: Pushes payload to backend.
    def push
      instrument("push.#{InstrumentationNamespace}") do |payload|
        payload[:payload] = self
        job.run_hook(:push) { Qu.backend.push(self) }
      end
    end

    private

    def constantize(class_name)
      return unless class_name
      return class_name if class_name.is_a?(Class)
      constant = Object
      class_name.split('::').each do |name|
        constant = constant.const_get(name) || constant.const_missing(name)
      end
      constant
    end

    def instrumenter
      Qu.instrumenter
    end

    def_delegators :instrumenter, :instrument
  end
end

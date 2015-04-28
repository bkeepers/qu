require 'ostruct'

module Qu
  class Payload < OpenStruct
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
      @queue ||= begin
        if klass
          Qu.queues[klass.queue] || raise("Queue #{klass.queue} is not registered")
        else
          raise "Please set the klass for the payload."
        end
      end
    end

    def perform
      job.run_hook(:perform) do
        Qu.instrument("perform") do |ipayload|
          ipayload[:payload] = self
          job.perform
        end
      end

      job.run_hook(:complete) { queue.complete(self) }
    rescue Qu::Worker::Abort
      abort
    rescue => exception
      fail(exception)
    end

    def abort
      job.run_hook(:abort) { queue.abort(self) }
      raise
    end

    def fail(exception)
      job.run_hook(:fail, exception) { queue.fail(self) }
      Qu::Failure.create(self, exception)
    end

    # Internal: Pushes payload to queue.
    def push
      self.pushed_at = Time.now.utc

      job.run_hook(:push) { queue.push(self) }
    end

    def attributes
      {
        :id => id,
        :klass => klass.to_s,
        :args => args,
      }
    end

    def attributes_for_push
      attributes
    end

    def to_s
      "#{id}:#{klass}:#{args.inspect}"
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
  end
end

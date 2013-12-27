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
      constantize(super)
    end

    def job
      @job ||= klass.load(self)
    end

    def queue
      (klass.instance_variable_get(:@queue) || 'default').to_s
    end

    def perform
      job.run_hook(:perform)  { job.perform }
      job.run_hook(:complete) { Qu.backend.complete(self) }
    rescue Qu::Worker::Abort
      job.run_hook(:abort) do
        Qu.backend.abort(self)
      end
      raise
    rescue => e
      job.run_hook(:failure, e) do
        Qu.failure.create(self, e)
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

    protected

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

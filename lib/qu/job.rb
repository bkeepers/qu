module Qu
  class Job
    include Qu::Hooks
    define_hooks :enqueue, :perform, :complete, :release, :failure

    attr_accessor :payload

    def self.queue(name = nil)
      @queue = name.to_s if name
      @queue ||= 'default'
    end

    def self.load(payload)
      allocate.tap do |job|
        job.payload = payload
        job.send :initialize, *payload.args
      end
    end

    def self.create(*args)
      Payload.new(:klass => self, :args => args).tap do |payload|
        payload.job.run_hook(:enqueue) { Qu.backend.enqueue payload }
      end
    end
  end
end

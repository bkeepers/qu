module Qu
  class Job
    include Qu::Hooks
    define_hooks :push, :perform, :complete, :abort, :fail

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
      Payload.new(:klass => self, :args => args).tap { |payload| payload.push }
    end

    # Public: Feel free to override this in your class with specific arg names
    # and all that.
    def initialize(*)
    end

    # Public: Feel free to override this as well.
    def perform
    end

    # Public: Gives you access to Qu's logger in your job.
    def logger
      Qu.logger
    end
  end
end

require "qu/failure/log"

module Qu
  module Failure
    # Public: Creates a failure for the given payload and exception using the
    # current failure queue.
    #
    # payload - The Qu::Payload that raised an exception when performing.
    # exception - The exception raised.
    #
    # Returns nothing.
    def self.report(job_payload, exception)
      Qu.instrument("failure_report") do |payload|
        payload[:payload] = job_payload
        payload[:exception] = exception

        queue.report(job_payload, exception)
      end
    end

    # Public: Allows user to change failure queue.
    def self.queue=(queue)
      @queue = queue
    end

    # Private: Returns the current failure queue.
    def self.queue
      @queue ||= Failure::Log
    end
  end
end

require "qu/failure/log"

module Qu
  module Failure
    # Public: Reports a failure for the given payload and exception using the
    # current failure reporter.
    #
    # payload - The Qu::Payload that raised an exception when performing.
    # exception - The exception raised.
    #
    # Returns nothing.
    def self.report(job_payload, exception)
      Qu.instrument("failure_report") do |payload|
        payload[:payload] = job_payload
        payload[:exception] = exception

        reporter.report(job_payload, exception)
      end
    end

    # Public: Allows user to change failure reporter.
    def self.reporter=(reporter)
      @reporter = reporter
    end

    # Private: Returns the current failure reporter.
    def self.reporter
      @reporter ||= Failure::Log
    end
  end
end

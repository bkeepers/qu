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
    def self.report(payload, exception)
      Qu.instrument("failure_create") do |ipayload|
        ipayload[:payload] = payload
        ipayload[:exception] = exception

        queue.report(payload, exception)
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

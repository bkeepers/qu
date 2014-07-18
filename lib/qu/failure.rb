require "qu/failure/log"
require "qu/instrumenter"

module Qu
  module Failure
    extend Qu::Instrumenter

    # Public: Creates a failure for the given payload and exception using the
    # current failure queue.
    #
    # payload - The Qu::Payload that raised an exception when performing.
    # exception - The exception raised.
    #
    # Returns nothing.
    def self.create(payload, exception)
      instrument("failure_create.#{InstrumentationNamespace}") do |ipayload|
        ipayload[:payload] = payload
        ipayload[:exception] = exception

        queue.create(payload, exception)
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

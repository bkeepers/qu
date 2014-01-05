require "qu/failure/log"
require "qu/instrumenter"

module Qu
  module Failure
    extend Qu::Instrumenter

    # Public: Creates a failure for the given payload and exception using the
    # current failure backend.
    #
    # payload - The Qu::Payload that raised an exception when performing.
    # exception - The exception raised.
    #
    # Returns nothing.
    def self.create(payload, exception)
      instrument("failure.#{InstrumentationNamespace}") do |ipayload|
        ipayload[:payload] = payload
        ipayload[:exception] = exception

        backend.create(payload, exception)
      end
    end

    # Public: Allows user to change failure backend.
    def self.backend=(backend)
      @backend = backend
    end

    # Private: Returns the current failure backend.
    def self.backend
      @backend ||= Failure::Log
    end
  end
end
